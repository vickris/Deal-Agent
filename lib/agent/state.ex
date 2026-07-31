defmodule Agent.State do
  @moduledoc """
  Holds the runtime state for a single agent execution.
  """

  defstruct [
    :goal,
    :status,
    :iteration,
    :messages,
    :trace
  ]
end
