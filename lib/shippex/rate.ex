defmodule Shippex.Rate do
  @enforce_keys [:service, :price]
  defstruct [:service, :price]
end
