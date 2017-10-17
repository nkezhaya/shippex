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
end
