defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "label generated" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination(), Helper.package())

    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "rates generated for canada" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("CA"), Helper.package())

    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "rates generated for mexico" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("MX"), Helper.package())
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end
end
