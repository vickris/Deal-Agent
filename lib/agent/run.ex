defmodule Agent.Run do
  @moduledoc """
  Represents a completed execution of an agent, including the goal, answer, status, trace, and timestamps.
  """
  @enforce_keys [:goal, :status]
  defstruct [
    :goal,
    :status,
    :answer,
    :trace,
    :iterations,
    :started_at,
    :finished_at,
    :verification
  ]
end
