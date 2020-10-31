defmodule Shippex.UPS.RateTest do
  use ExUnit.Case

  @moduletag :skip

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "rates generated, label fetched", %{shipment: shipment} do
    rates(shipment)
  end

  test "rates generated, label fetched with metric", %{shipment: shipment} do
    Application.put_env(:shippex, :distance_unit, :cm)
    Application.put_env(:shippex, :weight_unit, :kg)

    rates(shipment)
  end

  test "rates generated for canada", %{shipment: shipment} do
    destination =
      Shippex.Address.new!(%{
        name: "Canada Name",
        phone: "123-123-1234",
        address: "655 Burrard St",
        city: "Vancouver",
        state: "BC",
        zip: "V6C 2R7",
        country: "CA"
      })

    shipment = Shippex.Shipment.new!(shipment.from, destination, shipment.package)

    rates(shipment)
  end

  test "rates generated for mexico", %{shipment: shipment} do
    destination =
      Shippex.Address.new!(%{
        name: "Mexico Name",
        phone: "123-123-1234",
        address: "Ferrol 4",
        city: "Ciudad de México",
        state: "CMX",
        zip: "03100",
        country: "MX"
      })

    shipment = Shippex.Shipment.new!(shipment.from, destination, shipment.package)

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
