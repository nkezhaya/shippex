defmodule Shippex.ShippexTest do
  use ExUnit.Case
  alias Shippex
  doctest Shippex

  test "fetch rates" do
    shipment = Helper.valid_shipment()

    rates = Shippex.fetch_rates(shipment, carriers: :ups, services: :usps_priority)

    assert length(rates) > 3

    rates = Shippex.fetch_rates(shipment, services: [:usps_priority, :usps_priority_express])

    assert length(rates) == 2

    Shippex.fetch_rates(shipment, carriers: :usps)
  end
end
