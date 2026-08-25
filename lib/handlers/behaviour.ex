defmodule Handlers.Behaviour do
  @moduledoc """
  Behaviour for deterministic programmatic handlers.
  """

  @callback handle(message :: map(), context :: map()) ::
              {:ok, response :: map()} | {:error, reason :: any()}
end
