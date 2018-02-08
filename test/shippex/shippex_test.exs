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

    assert Shippex.fetch_rates(shipment, carriers: :usps)
  end

  test "fetch international rates" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("CA"), Helper.package())

    [{:ok, rate1}, {:ok, rate2}] = Shippex.fetch_rates(shipment, services: [:usps_priority, :usps_priority_express])

    assert rate1.service.description == "Priority Mail International"
    assert rate2.service.description == "Priority Mail Express International"
  end
end
