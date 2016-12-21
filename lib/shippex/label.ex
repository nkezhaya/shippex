defmodule Shippex.Label do
  @enforce_keys [:tracking_number]
  defstruct [:rate, :tracking_number, :format, :image]
end
