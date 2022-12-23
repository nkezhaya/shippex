defmodule Shippex.Item do
  @moduledoc """
  Defines a struct for storing an `Item` in a `Package`.

  The `monetary_value` *might* be required depending on the origin/destination
  countries of the shipment. Both `monetary_value` and `insurance` are integers
  stored in USD cents.
  """

  @enforce_keys [:description, :monetary_value, :weight, :quantity]
  @fields ~w(description monetary_value weight quantity)a
  defstruct @fields

  @type t() :: %__MODULE__{
          description: nil | String.t(),
          monetary_value: nil | integer(),
          weight: nil | number(),
          quantity: nil | number()
        }

  @doc """
  Builds and returns an `Item`. Use this instead of directly initializing the
  struct.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    attrs = Map.take(attrs, @fields)
    struct(__MODULE__, attrs)
  end
end
