defmodule Shippex.USPS.RateTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "rates generated", %{shipment: shipment} do
    package = %{shipment.package | container: :box_large}
    shipment = %{shipment | package: package}
    {:ok, _} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
  end

  test "ground rates generated", %{shipment: shipment} do
    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    {:ok, _} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_retail_ground)
  end

  test "rates generated with insurance", %{shipment: shipment} do
    package = %{shipment.package | container: :box_large}
    shipment = %{shipment | package: package}
    {:ok, rate1} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)

    package = %{shipment.package | container: :box_large, insurance: 100}
    shipment = %{shipment | package: package}
    {:ok, rate2} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)

    assert rate1.price > rate2.price
  end

  test "intl rates generated", %{shipment: shipment} do
    destination = Shippex.Address.address(%{
      first_name: "Some",
      last_name: "Person",
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
    assert Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
  end
end
