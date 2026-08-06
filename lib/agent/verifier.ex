defmodule Agent.Verifier do
  @moduledoc """
  Verifies whether an agent execution satisfied
  the expected conditions.
  """

  alias Agent.State

  @spec verify(State.t(), keyword()) :: :ok | {:error, term()}
  def verify(%State{} = state, opts \\ []) do
    required_tools = Keyword.get(opts, :required_tools, [])

    with :ok <- verify_status(state),
         :ok <- verify_finished_event(state.trace),
         :ok <- verify_result(state.result),
         :ok <- verify_required_tools(state.trace, required_tools) do
      :ok
    end
  end

  defp verify_status(%State{status: :finished}), do: :ok
  defp verify_status(%State{status: status}), do: {:error, {:invalid_final_status, status}}

  defp verify_finished_event(trace) do
    case Enum.find(trace, fn step -> step.type == :finished end) do
      nil -> {:error, :missing_finished_event}
      _step -> :ok
    end
  end

  defp verify_result(nil), do: {:error, :missing_result}
  defp verify_result(_result), do: :ok

  defp verify_required_tools(trace, required_tools) do
    executed_tools =
      trace
      |> Enum.filter(fn step -> step.type == :tool_executed end)
      |> Enum.map(fn step -> step.payload.tool end)

    missing_tools = required_tools -- executed_tools

    if missing_tools == [] do
      :ok
    else
      {:error, {:missing_required_tools, missing_tools}}
    end
  end
end
