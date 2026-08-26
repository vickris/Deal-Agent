defmodule Agent.API do
  @moduledoc """
  Public API for executing agents.
  """

  def run(goal, opts) do
    opts =
      Keyword.put(
        opts,
        :goal,
        goal
      )

    with {:ok, pid} <-
           Agent.RunSupervisor.start_run(opts) do
      Agent.Runner.run(pid)
    else
      {:error, reason} ->
        IO.puts("Could not start run due to this error: #{inspect(reason)}")
    end
  end
end
