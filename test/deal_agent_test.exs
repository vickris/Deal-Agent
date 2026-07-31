defmodule DealAgentTest do
  use ExUnit.Case
  doctest DealAgent

  test "greets the world" do
    assert DealAgent.hello() == :world
  end
end
