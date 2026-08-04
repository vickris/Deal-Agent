defmodule Agent.State do
  @moduledoc """
  Holds the runtime state for a single agent execution.
  """

  defstruct [
    :goal,
    :status,
    :iteration,
    :context,
    :trace,
    :result
  ]

  def new(goal) do
    %__MODULE__{
      goal: goal,
      status: :running,
      iteration: 0,
      context: Agent.Context.new(goal),
      trace: []
    }
  end

  def trace(state, type, payload) do
    %{
      state
      | trace:
          Agent.Trace.record(
            state.trace,
            state.iteration,
            type,
            payload
          )
    }
  end

  def add_tool_result(state, result) do
    update_context(state, &Agent.Context.add_tool_result(&1, result))
  end

  def add_assistant_message(state, reply) do
    update_context(state, &Agent.Context.add_assistant_message(&1, reply))
  end

  def increment_iteration(state) do
    %{state | iteration: state.iteration + 1}
  end

  def finish(state, result) do
    %{state | status: :finished, result: result}
  end

  def fail(state, reason) do
    state
    |> trace(:failed, %{reason: reason})
    |> Map.put(:status, :failed)
    |> Map.put(:result, reason)
  end

  defp update_context(state, fun) do
    %{state | context: fun.(state.context)}
  end
end
