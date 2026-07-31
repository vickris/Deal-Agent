defmodule Agent.Loop do
  @moduledoc """
  Implements the main loop for the agent.
  """

  use GenServer
  alias Agent.State

  def start_link(initial_state \\ []) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @impl true
  def init(_initial_state) do
    {:ok, %State{}}
  end

  def run(goal) do
    GenServer.call(__MODULE__, {:run, goal})
  end

  @impl true
  def handle_call({:run, goal}, _from, _state) do
    state = %State{
      goal: goal,
      status: :running,
      iteration: 0,
      messages: [
        %{
          role: :user,
          content: goal
        }
      ],
      trace: []
    }

    result = step(state)

    {:reply, result, state}
  end

  defp step(state) do
    case LLM.Mock.chat(state.messages) do
      {:reply, reply} ->
        {:ok, reply}

      {:tool_call, tool, args} ->
        run_tool(state, tool, args)
    end
  end

  defp run_tool(state, tool, args) do
    case Tools.Registry.call(tool, args) do
      {:ok, result} ->
        next_state = %{
          state
          | messages:
              state.messages ++
                [
                  %{
                    role: :tool,
                    content: result
                  }
                ]
        }

        step(next_state)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
