defmodule Tools.SaveComparison do
  @moduledoc """
  Tool for saving comparison results.
  """

  @behaviour Tools.Behaviour

  @impl true
  def name, do: :save_comparison

  @impl true
  def description, do: "Requests that a completed comparison be persisted."

  @impl true
  def execute(args) do
    Handlers.Registry.call(
      :save_comparison,
      args,
      trusted_context()
    )
  end

  defp trusted_context do
    %{
      storage: %{
        can_save: true
      }
    }
  end
end
