defmodule Shippex.Shipment do
  @enforce_keys [:from, :to, :package]
  defstruct [:id, :from, :to, :package]
end
