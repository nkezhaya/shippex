defmodule Shippex.Rate do
  @moduledoc """
  A `Rate` is a representation of a price estimate from a given carrier for a
  `Service`, which is typically selected by the end user for a desired shipping
  speed.
  """

  alias Shippex.Service

  @enforce_keys [:service, :price, :line_items]
  defstruct [:service, :price, :line_items]

  @type t :: %__MODULE__{
          service: Service.t(),
          price: integer(),
          line_items: nil | [%{name: String.t(), price: integer()}]
        }
end
