defmodule Agent.Verifier do
  @moduledoc """
  Verifies whether an agent execution satisfied
  the expected conditions.
  """

  @spec verify(%{trace: [map()]}) :: :ok | {:error, term()}
  def verify(state) do
    verify_finished(state)
  end

  defp verify_finished(state) do
    if finished?(state.trace) do
      :ok
    else
      {:error, :agent_never_finished}
    end
  end

  defp finished?(trace) do
    Enum.any?(trace, &(&1.type == :finished))
  end
end
