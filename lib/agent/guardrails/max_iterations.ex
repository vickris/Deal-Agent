defmodule Agent.Guardrails.MaxIterations do
  @moduledoc """
  Guardrail for enforcing maximum iteration limits.
  """

  @max_iterations 5

  @doc """
  Check if iteration count exceeds maximum allowed iterations.
  """
  def check(state) when is_integer(state.iteration) and is_integer(@max_iterations) do
    if state.iteration >= @max_iterations do
      {:error, :max_iterations_reached}
    else
      :ok
    end
  end
end
