defmodule Tools.Echo do
  @moduledoc """
  A simple module for echoing values.
  """
  @behaviour Tools.Behaviour

  @impl true
  def name, do: :echo

  @impl true
  def description, do: "A simple tool that echoes back the input value."

  @impl true
  def execute(%{"text" => text}) do
    {:ok, text}
  end

  def execute(%{text: text}) do
    {:ok, text}
  end

  def execute(_), do: {:error, :invalid_input}
end
