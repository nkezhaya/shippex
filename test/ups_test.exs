defmodule UPSTest do
  use ExUnit.Case

  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "rates generated, label fetched", %{shipment: shipment} do
    rates(shipment)
  end

  test "rates generated, label fetched with metric", %{shipment: shipment} do
    Application.put_env(:shippex, :distance_unit, :cm)
    Application.put_env(:shippex, :weight_unit, :kg)

    rates(shipment)
  end

  defp rates(shipment) do
    # Fetch rates
    rates = shipment
      |> Shippex.Carrier.UPS.fetch_rates

    assert rates

    # Accept one of the services and print the label
    {:ok, rate} = Enum.shuffle(rates) |> hd

    {:ok, label} = shipment
      |> Shippex.Carrier.UPS.fetch_label(rate)

    assert label
  end
end
