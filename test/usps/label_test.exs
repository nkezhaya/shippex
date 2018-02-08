defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "labels generated" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination(), Helper.package())

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "labels generated for canada" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("CA"), Helper.package())

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "labels generated for mexico" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("MX"), Helper.package())

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

    {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end
end
