defmodule Agent.Run do
  defstruct [
    :goal,
    :answer,
    :status,
    :trace,
    :iterations,
    :started_at,
    :finished_at
  ]

end
