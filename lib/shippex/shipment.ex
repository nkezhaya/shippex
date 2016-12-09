defmodule Shippex.Shipment do
  @enforce_keys [:from, :to, :package]
  defstruct [:from, :to, :package]
end
