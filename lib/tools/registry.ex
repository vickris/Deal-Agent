defmodule Tools.Registry do
  @moduledoc """
  Finds and executes registered tools.
  """
  alias Tools.Echo

  @tools %{
    echo: Echo
  }

  def call(tool_name, args) do
    case Map.fetch(@tools, tool_name) do
      {:ok, module} ->
        module.execute(args)

      :error ->
        {:error, :unknown_tool}
    end
  end

end
