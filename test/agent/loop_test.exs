defmodule Agent.LoopTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      case Process.whereis(Agent.Loop) do
        nil -> :ok
        pid -> GenServer.stop(pid)
      end
    end)

    :ok
  end

  test "completes a normal run" do
    start_loop(:normal)

    assert {:ok, "Done!", state} =
             Agent.Loop.run("Hello")

    assert state.status == :finished

    assert Enum.any?(
             state.trace,
             &(&1.type == :tool_completed and
                 &1.payload.tool == :echo)
           )
  end

  test "stops a model that loops forever" do
    start_loop(:loop_forever)

    assert {:error, :max_iterations_reached, state} =
             Agent.Loop.run("Keep repeating")

    assert state.status == :failed
  end

  test "rejects an unknown tool" do
    start_loop(:unknown_tool)

    assert {:error, :unknown_tool, state} =
             Agent.Loop.run("Run a tool")

    assert state.status == :failed

    assert Enum.any?(
             state.trace,
             &(&1.type == :tool_failed and
                 &1.payload.reason == :unknown_tool)
           )
  end

  test "rejects hallucinated success" do
    start_loop(:hallucinate_success)

    assert {:error, {:missing_required_tools, [:echo]}, state} =
             Agent.Loop.run("Complete the task")

    assert state.status == :failed

    refute Enum.any?(
             state.trace,
             &(&1.type == :tool_completed)
           )
  end

  test "stops execution when the tool-call budget is exhausted" do
    start_supervised!({
      Agent.Loop,
      [
        llm: {
          LLM.Mock,
          mode: :loop_forever
        },
        guardrails: [
          max_iterations: 20,
          max_tool_calls: 3,
          max_context_messages: 6
        ],
        verification: [
          required_tools: [:echo]
        ]
      ]
    })

    assert {:error, :max_tool_calls_reached, state} =
             Agent.Loop.run("Run a slow tool")

    assert state.status == :failed
    assert state.tool_calls == 3

    completed_tool_calls =
      Enum.count(
        state.trace,
        &(&1.type == :tool_completed and
            &1.payload.tool == :echo)
      )

    assert completed_tool_calls == 3
  end

  test "stops execution after the total time budget is exhausted" do
    start_supervised!({
      Agent.Loop,
      [
        llm: {
          LLM.Mock,
          [
            mode: :slow_loop,
            sleep_ms: 20
          ]
        },
        guardrails: [
          max_iterations: 20,
          max_tool_calls: 20,
          max_execution_time_ms: 35,
          max_context_messages: 6
        ],
        verification: []
      ]
    })

    assert {
             :error,
             {
               :max_execution_time_reached,
               details
             },
             state
           } =
             Agent.Loop.run("Run slowly")

    assert state.status == :failed
    assert details.elapsed_ms >= details.maximum_ms

    assert Enum.any?(
             state.trace,
             &(&1.type == :failed)
           )
  end

  defp start_loop(mode) do
    Agent.Loop.start_link(
      llm: {LLM.Mock, mode: mode},
      verification: [required_tools: [:echo]]
    )
  end
end
