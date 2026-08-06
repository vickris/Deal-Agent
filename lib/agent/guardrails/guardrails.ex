defmodule Agent.Guardrails do
  alias Agent.Guardrails.{
    MaxContextMessages,
    MaxIterations
  }

  def check_iterations(state, opts) do
    MaxIterations.check(state, opts)
  end

  def check_context(state, opts) do
    MaxContextMessages.check(state, opts)
  end
end
