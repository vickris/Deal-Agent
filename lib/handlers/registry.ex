defmodule Handlers.Registry do
  alias Handlers.SaveComparison

  @handlers %{
    save_comparison: SaveComparison
  }

  def call(name, input, context) do
    case Map.fetch(@handlers, name) do
      {:ok, module} ->
        module.handle(input, context)

      :error ->
        {:error, :unknown_handler}
    end
  end
end
