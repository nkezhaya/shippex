defmodule Shippex.USPS.RateTest do
  use ExUnit.Case

  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "rates generated", %{shipment: shipment} do
    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, "priority")
    assert is_list(rates) and length(rates) > 0
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, "all")
    assert is_list(rates) and length(rates) > 0
  end
end
