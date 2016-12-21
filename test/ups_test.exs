defmodule UPSTest do
  use ExUnit.Case
  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "rates generated, label fetched", %{shipment: shipment} do
    # Fetch rates
    rates = shipment
      |> Shippex.Carriers.UPS.fetch_rates

    assert rates

    # Accept one of the services and print the label
    {:ok, rate} = Enum.shuffle(rates) |> hd

    {:ok, label} = shipment
      |> Shippex.Carriers.UPS.fetch_label(rate)

    assert label
  end
end
