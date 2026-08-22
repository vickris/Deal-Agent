# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

DealAgent is an Elixir agent framework (not the shopping/deal-finding app itself — `lib/shopping/` is a placeholder for that layer and is currently empty). The framework runs an LLM-driven tool-use loop as an OTP `GenServer`, with deterministic context compression, iteration/context guardrails, and post-run verification, and it exposes a full execution trace. It has no dependencies (`mix.exs` deps list is empty) — everything is built on stdlib/OTP.

Elixir was chosen for the BEAM properties: each agent run is an isolated process (one crash doesn't affect others), OTP supervision gives automatic restarts, and message passing keeps tool execution clean.

## Commands

```bash
mix deps.get           # fetch deps (currently none declared)
mix compile             # compile
mix test                 # run the full test suite
mix test test/agent/context_test.exs        # run one test file
mix test test/agent/context_test.exs:21     # run a single test by line number
mix format                # format per .formatter.exs
```

There is no Mix task or CLI entry point for actually driving the agent yet — it's exercised via `Agent.Loop.start_link/1` + `Agent.Loop.run/1` (see tests below for the calling convention).

## Architecture

### The run loop (`lib/agent/`)

`Agent.Loop` is a `GenServer` registered under its own module name (`name: __MODULE__`), so **only one agent run can be active at a time process-wide**. `start_link/1` takes `:llm` (required, `{module, opts}` tuple satisfying `LLM.Client`), `:verification` opts, and `:guardrails` opts. `run/1` is a synchronous `GenServer.call` that drives one goal to completion (or failure) before returning — tests must stop the process (`GenServer.stop/1`) between runs since the name is global.

Execution is recursive, not literally looped: `step/3` → `call_llm/3` → (on `{:tool_call, ...}`) `run_tool/5` → back into `step/3`. Each cycle:

1. `Guardrails.check_iterations/2` — fails with `:max_iterations_reached` once `state.iteration` hits the configured max (default 5).
2. `prepare_context/2` — calls `Agent.Context.compress/2`; if compression still can't fit under the limit it fails with `:context_limit_too_small`.
3. `Guardrails.check_context/2` — a second check on the *final* message count actually sent to the model.
4. Iteration increments, a `:model_call` trace step is recorded, then the configured LLM module's `chat/2` is invoked.
5. The LLM returns either `{:reply, text}` (run finishes) or `{:tool_call, tool_name, args}` (dispatched through `Tools.Registry`, result appended to context, loop repeats).

Every state transition is recorded via `Agent.State.trace/3` into an append-only `Agent.Trace.Step` list — this is the audit trail returned to callers on both success and failure paths, not just an internal debug log.

### Context and compression (`Agent.Context`)

`Agent.Context` owns exactly what gets sent to the model. The goal and (optional) system prompt are **never** dropped; only the accumulated `messages` list (tool results, assistant replies) is subject to compression. `compress/2` is deterministic (no LLM call): once the rendered message count exceeds `:max_context_messages`, the oldest messages are folded into a single running `summary` string (capped at `:summary_char_limit`, oldest content trimmed first) and replaced by one `:system` message. This repeats across iterations — the summary keeps absorbing newly-aged-out messages rather than resetting. `compress/2` is a guardrail-facing function; it errors with `:context_limit_too_small` if the configured max is too small to hold the fixed messages (goal + optional system prompt + at least one summary/message slot).

### Guardrails (`lib/agent/guardrails/`)

`Agent.Guardrails` is a thin dispatcher over two independent checks — `MaxIterations` (`state.iteration >= max`) and `MaxContextMessages` (rendered message count vs. max, default 8). Both read options from the same `guardrails` keyword list passed to `Agent.Loop.start_link/1`; there's no shared config struct.

### Verification (`Agent.Verifier`)

Runs once, after the loop naturally reaches a `{:reply, ...}`, before the result is handed back — it's what turns a plausible-looking `{:ok, ...}` into an `{:error, ...}` when the run didn't actually do what was asked. It checks: final status is `:finished`, a `:finished` trace event exists, `state.result` is non-nil, and every tool in `:required_tools` actually appears as a `:tool_completed` trace step. This is the mechanism that catches an LLM hallucinating a success message without calling the tools it claimed to (`LLM.Mock`'s `:hallucinate_success` mode exists specifically to exercise this).

### LLM boundary (`lib/llm/`)

`LLM.Client` is a one-callback behaviour: `chat([message], opts) :: {:reply, text} | {:tool_call, atom, map}`. `LLM.Mock` is the only implementation and is what the test suite runs against, selected via `mode:` in opts (`:normal`, `:loop_forever` — used to exercise the iteration guardrail, `:hallucinate_success`, `:unknown_tool`). `Llm.Config` (note: lowercase `Llm`, inconsistent with `LLM.Client`/`LLM.Mock`) is a scaffolded `{module, options}` struct not yet referenced anywhere — a real provider client would implement `LLM.Client` and be passed to `Agent.Loop` as `{module, opts}` the same way the mock is.

### Tools (`lib/tools/`)

`Tools.Behaviour` requires `name/0`, `description/0`, `execute/1`. `Tools.Registry.call/2` dispatches through a hardcoded `@tools` map (currently just `echo: Tools.Echo`) — adding a tool means adding it to that map, there's no dynamic registration. An unknown tool name surfaces as `{:error, :unknown_tool}`, which `Agent.Loop` turns into a failed run with a `:tool_failed` trace step (this is also how a hallucinated/unknown tool call from the model gets caught, separately from `Agent.Verifier`'s required-tools check).

### Not yet wired up

`Agent.Run` (a struct meant to represent a completed run: goal/status/answer/trace/timestamps) exists but nothing currently constructs one — `Agent.Loop.run/1` currently returns raw `{:ok, result, %Agent.State{}}` / `{:error, reason, %Agent.State{}}` tuples instead.
