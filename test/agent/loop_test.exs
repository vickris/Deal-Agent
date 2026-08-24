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

  test "returns a verified successful run" do
    start_loop(:normal)

    assert {:ok, run} =
             Agent.Loop.run("Hello")

    assert run.execution_status == :finished
    assert run.verification_status == :passed
    assert run.answer == "Done!"
    assert run.tool_calls == 1
    assert run.iterations == 2
    assert run.duration_ms >= 0
  end

  test "stops a model that loops forever" do
    start_loop(:loop_forever)

    assert {:error, run} =
             Agent.Loop.run("Keep repeating")

    assert run.execution_status == :failed
    assert run.verification_status == :not_run
    assert run.error == :max_iterations_reached
  end

  test "rejects an unknown tool" do
    start_loop(:unknown_tool)

    assert {:error, run} =
             Agent.Loop.run("Run a tool")

    assert run.execution_status == :failed
    assert run.error == :unknown_tool
  end

  test "returns a completed but unverified run" do
    start_loop(:hallucinate_success)

    assert {:error, run} =
             Agent.Loop.run("Complete the task")

    assert run.execution_status == :finished

    assert run.verification_status ==
             :failed

    assert run.answer ==
             "I successfully compared every supermarket."

    assert run.verification_error ==
             {:missing_required_tools, [:echo]}
  end

  test "returns an execution failure" do
    start_loop(:loop_forever)

    assert {:error, run} =
             Agent.Loop.run("Keep repeating")

    assert run.execution_status == :failed
    assert run.verification_status == :not_run
    assert run.error == :max_iterations_reached
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

    assert {:error, run} =
             Agent.Loop.run("Keep repeating")

    assert run.execution_status == :failed
    assert run.verification_status == :not_run
    assert {:max_execution_time_reached, _time_ms} = run.error
  end

  defp start_loop(mode) do
    Agent.Loop.start_link(
      llm: {LLM.Mock, mode: mode},
      verification: [required_tools: [:echo]]
    )
  end
end
