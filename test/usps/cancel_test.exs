defmodule ExShip.USPS.CancelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "cancel domestic transaction" do
    shipment = ExShip.Shipment.new!(Helper.origin(), Helper.destination(), Helper.package())

    cancel_shipment(shipment, ExShip.Service.get(:usps_priority))
    cancel_shipment(shipment, ExShip.Service.get(:usps_priority_express))
  end

  test "cancel international transaction" do
    shipment = ExShip.Shipment.new!(Helper.origin(), Helper.destination("MX"), Helper.package())

    cancel_shipment(shipment, ExShip.Service.get(:usps_priority))
    cancel_shipment(shipment, ExShip.Service.get(:usps_priority_express))
  end

  defp cancel_shipment(shipment, service) do
    {:ok, transaction} = ExShip.Carrier.USPS.create_transaction(shipment, service)
    tracking_number = transaction.label.tracking_number
    {:ok, _} = ExShip.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    # Try again
    {:error, reason} = ExShip.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    assert reason =~ ~r/already/i
  end
end
