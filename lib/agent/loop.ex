defmodule Agent.Loop do
  @moduledoc """
  Implements the main loop for the agent.
  """

  use GenServer
  alias Agent.State

  def start_link(opts \\ []) do
    llm = Keyword.fetch!(opts, :llm)
    GenServer.start_link(__MODULE__, llm, name: __MODULE__)
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

    case step(state) do
      {:ok, result, final_state} ->
        case Agent.Verifier.verify(final_state) do
          :ok ->
            {:reply, {:ok, result}, final_state}

          {:error, reason} ->
            {:reply, {:error, reason}, final_state}
        end


      {:error, reason, final_state} ->
        {:reply, {:error, reason}, final_state}
    end
  end

  defp step(state) do
    state = trace(state, :model_call, %{messages: state.messages})

    case LLM.Mock.chat(state.messages) do
      {:reply, reply} ->
        state =
          state
          |> trace(:model_finished, %{
            answer: reply
          })
          |> Map.put(:status, :finished)
        {:ok, reply, state}

      {:tool_call, tool, args} ->
        state = trace(state, :tool_requested, %{tool: tool, arguments: args})
        run_tool(state, tool, args)
    end
  end

  defp run_tool(state, tool, args) do
    case Tools.Registry.call(tool, args) do
      {:ok, result} ->
        state = state
        |> trace(:tool_completed, %{tool: tool, result: result})
        |> append_tool_message(result)

        step(state)

      {:error, reason} ->
        state =
        trace(state, :tool_failed, %{
          tool: tool,
          reason: reason
        })

        {:error, reason, state}
    end
  end

  defp trace(state, type, payload) do
    %{
      state
      | trace:
          Agent.Trace.record(
            state.trace,
            state.iteration,
            type,
            payload
          )
    }
  end

  defp append_tool_message(state, result) do
    tool_message = %{
      role: :tool,
      content: result
    }

    %{
      state
      | messages: state.messages ++ [tool_message]
    }
  end
end
