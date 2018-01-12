defmodule Shippex.USPS.RateTest do
  use ExUnit.Case

  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "rates generated", %{shipment: shipment} do
    package = %{shipment.package | container: :box_large}
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

    {:ok, label} = Shippex.Carrier.USPS.fetch_label(shipment, rate.service)

    assert label
    assert label.tracking_number
    assert label.image
  end

  test "ground rates generated", %{shipment: shipment} do
    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, "RETAIL GROUND")
    assert is_list(rates) and length(rates) > 0
  end

  test "intl rates generated", %{shipment: shipment} do
    destination = Shippex.Address.address(%{
      name: "Some Person",
      phone: "778-123-1234",
      address: "4575 Clancy Loranger Way",
      city: "Vancouver",
      state: "BC",
      zip: "V5Y 2M4",
      country: "CA"
    })

    shipment = %{shipment | to: destination}

    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    Shippex.Carrier.USPS.fetch_rate(shipment, "ALL")
  end
end
