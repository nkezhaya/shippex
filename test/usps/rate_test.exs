defmodule Shippex.USPS.RateTest do
  use ExUnit.Case

  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  describe "addresses" do
    test "validate address" do
      valid_address = Shippex.Address.address(%{
        "name" => "Earl G",
        "phone" => "123-456-7890",
        "address" => "404 S Figueroa St",
        "address_line_2" => "Suite 101",
        "city" => "Los Angeles",
        "state" => "CA",
        "zip" => "90071"
      })

      Shippex.Carrier.USPS.validate_address(valid_address)
    end
  end

  describe "rates" do
    test "rates generated", %{shipment: shipment} do
      package = %{shipment.package | container: :variable}
      shipment = %{shipment | package: package}
      rates = Shippex.Carrier.USPS.fetch_rate(shipment, "priority")
      assert is_list(rates) and length(rates) > 0
      rates = Shippex.Carrier.USPS.fetch_rate(shipment, "all")
      assert is_list(rates) and length(rates) > 0
    end
  end
end
