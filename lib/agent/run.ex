defmodule Agent.Run do
  @moduledoc """
  Represents a completed outcome of a single agent execution.
  """
  @enforce_keys [
    :goal,
    :execution_status,
    :verification_status,
    :iterations,
    :tool_calls,
    :started_at,
    :finished_at,
    :duration_ms,
    :trace
  ]
  defstruct [
    :goal,
    :execution_status,
    :verification_status,
    :answer,
    :error,
    :iterations,
    :tool_calls,
    :started_at,
    :finished_at,
    :duration_ms,
    :trace,
    :verification_error
  ]
end
