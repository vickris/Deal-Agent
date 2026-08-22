defmodule Tools.Sleep do
  @moduledoc """
  A tool that sleeps for a specified duration.
  Testing execution time guardrail
  """

  @behaviour Tools.Behaviour

  @impl true
  def name, do: :sleep

  @impl true
  def description, do: "A tool that sleeps for a specified duration in seconds."

  @impl true
  def execute(%{milliseconds: milliseconds})
      when is_integer(milliseconds) and milliseconds >= 0 do
    Process.sleep(milliseconds)

    {:ok, "Slept for #{milliseconds} milliseconds"}
  end

  def execute(%{"milliseconds" => milliseconds})
      when is_integer(milliseconds) and milliseconds >= 0 do
    execute(%{milliseconds: milliseconds})
  end

  def execute(_args) do
    {:error, :invalid_arguments}
  end
end
