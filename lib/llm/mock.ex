defmodule LLM.Mock do
  @moduledoc """
  Mock implementation of the LLM client for testing purposes.
  """

  @behaviour LLM.Client

  @impl true
  def chat(messages) do
    last =
      List.last(messages)

    case last do
      %{role: :user} ->
        {:tool_call, :echo, %{text: last.content}}

      %{role: :tool} ->
        {:reply, "Done!"}

      _ ->
        {:reply, "I'm confused."}
    end
  end

end
