defmodule Shippex.Rate do
  @moduledoc """
  A `Rate` is a representation of a price estimate from a given carrier for a
  `Service`, which is typically selected by the end user for a desired shipping
  speed.
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:service, :price]
  defstruct [:service, :price]
end
