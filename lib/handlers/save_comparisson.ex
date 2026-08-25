defmodule Handlers.SaveComparison do
  @moduledoc """
  Handler for saving comparison results.
  """

  @behaviour Handlers.Behaviour

  @impl true
  def handle(message, context) do
    case message do
      %{"type" => "save_comparison", "data" => data} ->
        save_comparison(data, context)

      _ ->
        {:error, :invalid_message}
    end
  end

  defp save_comparison(data, context) do
    # Implement the logic to save the comparison result here.
    # You can use the `data` and `context` to perform the necessary operations.
    # For example, you might want to store the data in a database or log it.

    # For demonstration purposes, we'll just return an :ok tuple.
    {:ok, %{message: "Comparison result saved successfully", data: data}}
  end
end
