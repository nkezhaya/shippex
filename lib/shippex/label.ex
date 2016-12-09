defmodule Shippex.Label do
  @enforce_keys [:tracking_number, :format, :image]
  defstruct [:tracking_number, :format, :image]
end
