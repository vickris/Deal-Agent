defmodule Agent.Loop do
  @moduledoc """
  Implements the main loop for the agent.
  """

  use GenServer

  alias Agent.Context
  alias Agent.Guardrails
  alias Agent.State

  def start_link(opts \\ []) do
    llm = Keyword.fetch!(opts, :llm)
    verification = Keyword.get(opts, :verification, [])
    guardrails = Keyword.get(opts, :guardrails, [])

    server_state = %{
      llm: llm,
      verification: verification,
      guardrails: guardrails
    }

    GenServer.start_link(__MODULE__, server_state, name: __MODULE__)
  end

  @impl true
  def init(server_state) do
    {:ok, server_state}
  end

  def run(goal) do
    GenServer.call(__MODULE__, {:run, goal})
  end

  @impl true
  def handle_call(
        {:run, goal},
        _from,
        %{llm: llm, verification: verification, guardrails: guardrails} = server_state
      ) do
    execution_state = State.new(goal)

    run =
      case step(execution_state, llm, guardrails) do
        {:ok, _result, final_execution_state} ->
          build_verified_run(final_execution_state, verification)

        {:error, reason, final_execution_state} ->
          Agent.Run.Builder.execution_failed(
            final_execution_state,
            reason
          )
      end

    {:reply, public_result(run), server_state}
  end

  defp build_verified_run(
         final_state,
         verification
       ) do
    candidate =
      Agent.Run.Builder.success(final_state)

    case Agent.Verifier.verify(
           candidate,
           verification
         ) do
      :ok ->
        candidate

      {:error, reason} ->
        Agent.Run.Builder.verification_failed(
          final_state,
          reason
        )
    end
  end

  defp step(state, llm, guardrails) do
    case prepare_context(state, guardrails) do
      {:ok, state} ->
        run_checks(state, llm, guardrails)

      {:error, reason, failed_state} ->
        {:error, reason, failed_state}
    end
  end

  defp run_checks(state, llm, guardrails) do
    with :ok <- Guardrails.check_before_step(state, guardrails),
         {:ok, _} <- prepare_context(state, guardrails),
         :ok <- Guardrails.check_context(state, guardrails) do
      state
      |> State.increment_iteration()
      |> State.trace(:model_call, %{
        message_count: state.context |> Context.messages() |> length(),
        elapsed_ms: State.elapsed_ms(state)
      })
      |> call_llm(llm, guardrails)
    else
      {:error, reason, %State{} = failed_state} ->
        {:error, reason, failed_state}

      {:error, reason} ->
        failed_state = State.fail(state, reason)
        {:error, reason, failed_state}
    end
  end

  defp call_llm(state, {module, opts} = llm, guardrails) do
    case module.chat(Context.messages(state.context), opts) do
      {:reply, reply} ->
        state =
          state
          |> State.add_assistant_message(reply)
          |> State.trace(:model_finished, %{answer: reply})
          |> State.finish(reply)

        {:ok, reply, state}

      {:tool_call, tool, args} ->
        state = State.trace(state, :tool_requested, %{tool: tool, arguments: args})
        run_tool(state, tool, args, llm, guardrails)
    end
  end

  defp prepare_context(state, guardrails) do
    max_messages =
      Keyword.get(
        guardrails,
        :max_context_messages,
        8
      )

    summary_char_limit =
      Keyword.get(
        guardrails,
        :summary_char_limit,
        1_000
      )

    options = [
      max_messages: max_messages,
      summary_char_limit: summary_char_limit
    ]

    case Agent.Context.compress(
           state.context,
           options
         ) do
      {:ok, _context, %{compressed?: false}} ->
        {:ok, state}

      {:ok, context, metadata} ->
        compressed_state =
          state
          |> State.put_context(context)
          |> State.trace(
            :context_compressed,
            metadata
          )

        {:ok, compressed_state}

      {:error, reason} ->
        failed_state = State.fail(state, reason)
        {:error, reason, failed_state}
    end
  end

  defp run_tool(state, tool, args, llm, guardrails) do
    with :ok <- Guardrails.check_before_tool(state, guardrails) do
      execute_tool(state, tool, args, llm, guardrails)
    else
      {:error, reason} ->
        failed_state = State.fail(state, reason)
        {:error, reason, failed_state}
    end
  end

  defp execute_tool(state, tool, args, llm, guardrails) do
    state =
      state
      |> State.increment_tool_calls()

    state =
      State.trace(
        state,
        :tool_started,
        %{
          tool: tool,
          arguments: args,
          tool_call_number: state.tool_calls + 1
        }
      )

    case Tools.Registry.call(tool, args) do
      {:ok, result} ->
        state =
          state
          |> State.trace(:tool_completed, %{
            tool: tool,
            result: result,
            tool_call_number: state.tool_calls
          })
          |> State.add_tool_result(result)

        step(state, llm, guardrails)

      {:error, reason} ->
        failed_state =
          state
          |> State.trace(:tool_failed, %{
            tool: tool,
            reason: reason,
            tool_call_number: state.tool_calls
          })
          |> State.fail(reason)

        {:error, reason, failed_state}
    end
  end

  defp public_result(
         %Agent.Run{
           execution_status: :finished,
           verification_status: :passed
         } = run
       ) do
    {:ok, run}
  end

  defp public_result(%Agent.Run{} = run) do
    {:error, run}
  end
end
