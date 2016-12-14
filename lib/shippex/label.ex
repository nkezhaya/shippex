defmodule Shippex.Label do
  @enforce_keys [:rate, :tracking_number, :format, :image]
  defstruct [:rate, :tracking_number, :format, :image]
end
