defmodule Llm.Mock do
  @moduledoc """
  Mock implementation of the LLM client for testing purposes.
  """

  @behaviour Llm.Client

  @impl true
  def chat(messages) do
    # Simulate a response based on the input messages
    case messages do
      [%{role: :user, content: "Hello"}] ->
        {:reply, "Hi there! How can I assist you today?"}

      [%{role: :user, content: "Call tool"}] ->
        {:tool_call, :example_tool, %{param1: "value1", param2: "value2"}}

      _ ->
        {:reply, "I'm not sure how to respond to that."}
    end
  end

end
