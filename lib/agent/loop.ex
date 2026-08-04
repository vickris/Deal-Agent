defmodule Agent.Loop do
  @moduledoc """
  Implements the main loop for the agent.
  """

  use GenServer
  alias Agent.State

  def start_link(opts \\ []) do
    llm = Keyword.fetch!(opts, :llm)
    GenServer.start_link(__MODULE__, llm, name: __MODULE__)
  end

  @impl true
  def init(_initial_state) do
    {:ok, %State{}}
  end

  def run(goal) do
    GenServer.call(__MODULE__, {:run, goal})
  end

  @impl true
  def handle_call({:run, goal}, _from, _state) do
    state = State.new(goal)

    case step(state) do
      {:ok, result, final_state} ->
        case Agent.Verifier.verify(final_state) do
          :ok ->
            {:reply, {:ok, result}, final_state}

          {:error, reason} ->
            {:reply, {:error, reason}, final_state}
        end

      {:error, reason, final_state} ->
        {:reply, {:error, reason}, final_state}
    end
  end

  defp step(state) do
    with :ok <- Agent.Guardrails.check(state) do
        state
        |> State.increment_iteration()
        |> State.trace(:model_call, %{})
        |> call_llm()
    else
      {:error, reason} ->
        state = State.fail(state, reason)
        {:error, reason, state}
    end
  end

  defp call_llm(state) do
    case LLM.Mock.chat(Agent.Context.messages(state.context)) do
      {:reply, reply} ->
        state =
          state
          |> State.trace(:model_finished, %{answer: reply})
          |> State.finish(reply)

        {:ok, reply, state}

      {:tool_call, tool, args} ->
        state = State.trace(state, :tool_requested, %{tool: tool, arguments: args})
        run_tool(state, tool, args)
    end
  end

  defp run_tool(state, tool, args) do
    case Tools.Registry.call(tool, args) do
      {:ok, result} ->
        state =
          state
          |> State.trace(:tool_completed, %{tool: tool, result: result})
          |> State.add_tool_result(result)

        step(state)

      {:error, reason} ->
        state = State.trace(state, :tool_failed, %{tool: tool, reason: reason})
        {:error, reason, state}
    end
  end
end
