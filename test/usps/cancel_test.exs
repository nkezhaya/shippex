defmodule Shippex.USPS.CancelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "cancel domestic transaction" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination(), Helper.package())

    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, _} = Shippex.Carrier.USPS.cancel_transaction(shipment, rate.service)
  end

  test "cancel international transaction" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("MX"), Helper.package())
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, _} = Shippex.Carrier.USPS.cancel_transaction(shipment, rate.service)
  end
end
