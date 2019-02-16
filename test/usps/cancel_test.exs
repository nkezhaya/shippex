defmodule Shippex.USPS.CancelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "cancel domestic transaction" do
    shipment = Shippex.Shipment.new!(Helper.origin(), Helper.destination(), Helper.package())

    cancel_shipment(shipment, Shippex.Service.get(:usps_priority))
    cancel_shipment(shipment, Shippex.Service.get(:usps_priority_express))
  end

  test "cancel international transaction" do
    shipment = Shippex.Shipment.new!(Helper.origin(), Helper.destination("MX"), Helper.package())

    cancel_shipment(shipment, Shippex.Service.get(:usps_priority))
    cancel_shipment(shipment, Shippex.Service.get(:usps_priority_express))
  end

  defp cancel_shipment(shipment, service) do
    {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, service)
    tracking_number = transaction.label.tracking_number
    {:ok, _} = Shippex.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    # Try again
    {:error, reason} = Shippex.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    assert reason =~ ~r/already/i
  end
end
