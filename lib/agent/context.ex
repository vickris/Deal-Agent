defmodule Agent.Context do
  @moduledoc """
  Represents the conversation context sent to the model
  """

  defstruct [
    :system_prompt,
    messages: []
  ]

  def new(goal) do
    %__MODULE__{
      messages: [
        %{
          role: :user,
          content: goal
        }
      ]
    }
  end

  def add_tool_result(context, result) do
    message = %{
      role: :tool,
      content: result
    }

    %{
      context
      | messages: context.messages ++ [message]
    }
  end

  def add_assistant_message(context, reply) do
    assistant_message = %{
      role: :assistant,
      content: reply
    }

    %{
      context
      | messages: context.messages ++ [assistant_message]
    }
  end
end
