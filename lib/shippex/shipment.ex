defmodule Shippex.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a package description. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment.
  """

  @enforce_keys [:from, :to, :package]
  defstruct [:id, :from, :to, :package]
end
