defmodule Tools.Crash do
  @behaviour Tools.Behaviour

  @impl true
  def name, do: :crash

  @impl true
  def description do
    "Crashes intentionally for supervision tests."
  end

  @impl true
  def execute(_args) do
    raise "intentional tool crash"
  end
end
