defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "label generated", %{shipment: shipment} do
    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, "priority")
    assert is_list(rates) and length(rates) > 0

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.reject(& &1.service.code == "PRIORITY MAIL EXPRESS")
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
