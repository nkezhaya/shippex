defmodule Shippex.UPS.LabelTest do
  use ExUnit.Case

  @moduletag :skip

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "label fetched", %{shipment: shipment} do
    rates(shipment)
  end

  test "label fetched with metric", %{shipment: shipment} do
    Application.put_env(:shippex, :distance_unit, :cm)
    Application.put_env(:shippex, :weight_unit, :kg)

    rates(shipment)
  end

  defp rates(shipment) do
    # Fetch rates
    rates = Shippex.Carrier.UPS.fetch_rates(shipment)

    assert rates

    Enum.each(rates, fn rate ->
      {:ok, _} = rate
    end)

    # Accept one of the services and print the label
    {:ok, rate} = rates |> Enum.shuffle() |> hd

    {:ok, label} = Shippex.Carrier.UPS.create_transaction(shipment, rate.service)

    assert label
  end
end
