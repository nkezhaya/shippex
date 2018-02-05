defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "label generated" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination(), Helper.package())

    rate = Shippex.Carrier.USPS.fetch_rate(shipment, :all) |> random_rate()

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "rates generated for canada" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("CA"), Helper.package())

    rate = Shippex.Carrier.USPS.fetch_rate(shipment, :all) |> random_rate()

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  test "rates generated for mexico" do
    shipment = Shippex.Shipment.shipment(Helper.origin(), Helper.destination("MX"), Helper.package())
    rate = Shippex.Carrier.USPS.fetch_rate(shipment, :all) |> random_rate()

    {:ok, _} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
  end

  defp random_rate(rates) do
    rates
    |> Enum.filter(fn {code, _} -> code == :ok end)
    |> Enum.filter(fn {_, rate} ->
      rate.service.id in ~w(usps_priority usps_priority_express usps_parcel_ground)a
    end)
    |> Enum.map(fn {_, rate} -> rate end)
    |> Enum.shuffle
    |> hd
  end
end
