defmodule Agent.Guardrails do
  alias Agent.Guardrails.{
    MaxIterations
  }

  def check(state) do
    with :ok <- MaxIterations.check(state) do
      :ok
    end
  end
end
