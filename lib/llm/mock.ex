defmodule LLM.Mock do
  @moduledoc """
  Mock implementation of the LLM client for testing purposes.
  """

  @behaviour LLM.Client

  @impl true
  def chat(messages, opts \\ []) do
    mode = Keyword.get(opts, :mode, :loop_forever)

    case mode do
      :normal ->
        normal(messages)

      :loop_forever ->
        loop_forever(messages)

      :hallucinate_success ->
        hallucinate_success(messages)

      :unknown_tool ->
        unknown_tool(messages)
    end
  end


  defp normal(_messages) do
    :ok
  end

  defp loop_forever(messages) do
    last =
      List.last(messages)

    case last do
      %{role: :user, content: text} ->
        {:tool_call, :echo, %{text: text}}

      %{role: :tool, content: text} ->
        {:tool_call, :echo, %{text: text}}

      _ ->
        {:tool_call, :echo, %{text: "again"}}
    end
  end

  defp hallucinate_success(_messages) do
    {:reply, "I successfully compared every supermarket."}
  end

  defp unknown_tool(_messages) do
    {:tool_call, :delete_everything, %{}}
  end
end
