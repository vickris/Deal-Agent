defmodule Agent.APITest do
  use ExUnit.Case, async: true

  test "returns a verified successful run" do
    assert {:ok, run} =
             Agent.API.run(
               "Hello",
               llm: {LLM.Mock, mode: :normal},
               verification: [required_tools: [:echo]]
             )

    assert run.execution_status == :finished
    assert run.verification_status == :passed
    assert run.answer == "Done!"
    assert run.tool_calls == 1
    assert run.iterations == 2
    assert run.duration_ms >= 0
  end

  test "stops a model that loops forever" do
    assert {:error, run} =
             Agent.API.run(
               "Keep repeating",
               llm: {LLM.Mock, mode: :loop_forever},
               verification: [required_tools: [:echo]]
             )

    assert run.execution_status == :failed
    assert run.verification_status == :not_run
    assert run.error == :max_iterations_reached
  end

  test "rejects an unknown tool" do
    assert {:error, run} =
             Agent.API.run(
               "Run a tool",
               llm: {LLM.Mock, mode: :unknown_tool},
               verification: [required_tools: [:echo]]
             )

    assert run.execution_status == :failed
    assert run.error == :unknown_tool
  end

  test "returns a completed but unverified run" do
    assert {:error, run} =
             Agent.API.run(
               "Complete the task",
               llm: {LLM.Mock, mode: :hallucinate_success},
               verification: [required_tools: [:echo]]
             )

    assert run.execution_status == :finished

    assert run.verification_status ==
             :failed

    assert run.answer ==
             "I successfully compared every supermarket."

    assert run.verification_error ==
             {:missing_required_tools, [:echo]}
  end

  test "stops execution after the total time budget is exhausted" do
    assert {:error, run} =
             Agent.API.run(
               "Keep repeating",
               llm: {
                 LLM.Mock,
                 [
                   mode: :slow_loop,
                   sleep_ms: 100
                 ]
               },
               guardrails: [
                 max_execution_time_ms: 250
               ]
             )

    assert run.execution_status == :failed
    assert run.verification_status == :not_run
    assert {:max_execution_time_reached, _time_ms} = run.error
  end
end
