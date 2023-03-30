defmodule ExShip.ExShipTest do
  use ExUnit.Case
  alias ExShip
  doctest ExShip

  test "fetch rates" do
    shipment = Helper.valid_shipment()

    rates = ExShip.fetch_rates(shipment, carriers: :ups, services: :usps_priority)

    assert length(rates) > 3

    rates = ExShip.fetch_rates(shipment, services: [:usps_priority, :usps_priority_express])

    assert length(rates) == 2
  end

  test "fetch international rates" do
    shipment = ExShip.Shipment.new!(Helper.origin(), Helper.destination("CA"), Helper.package())

    [{:ok, rate1}, {:ok, rate2}] =
      ExShip.fetch_rates(shipment, services: [:usps_priority, :usps_priority_express])

    assert rate1.service.description == "Priority Mail International"
    assert rate2.service.description == "Priority Mail Express International"
  end
end
