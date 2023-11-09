defmodule ExShip.Schema do
  @moduledoc false
  defmacro __using__(_options) do
    type = ExShip.Config.key_type()

    case type do
      :binary_id ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id
        end

      _ ->
        quote do
          use Ecto.Schema
        end
    end
  end
end
