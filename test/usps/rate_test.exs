defmodule Shippex.USPS.RateTest do
  use ExUnit.Case

  alias Shippex.ISO
  alias Shippex.Carrier.USPS

  describe "domestic" do
    setup do
      [shipment: Helper.valid_shipment()]
    end

    test "rates generated", %{shipment: shipment} do
      package = %{shipment.package | container: :box_large}
      shipment = %{shipment | package: package}
      {:ok, _} = USPS.fetch_rate(shipment, :usps_priority)
    end

    test "ground rates generated", %{shipment: shipment} do
      package = %{shipment.package | container: :variable}
      shipment = %{shipment | package: package}
      {:ok, _} = USPS.fetch_rate(shipment, :usps_retail_ground)
    end

    test "ground rates generated with insurance", %{shipment: shipment} do
      package = %{shipment.package | container: :variable, insurance: nil}
      shipment = %{shipment | package: package}
      {:ok, rate1} = USPS.fetch_rate(shipment, :usps_retail_ground)

      package = %{shipment.package | container: :variable, insurance: 200_00}
      shipment = %{shipment | package: package}
      {:ok, rate2} = USPS.fetch_rate(shipment, :usps_retail_ground)

      assert rate1.price < rate2.price
    end

    test "rates generated with insurance", %{shipment: shipment} do
      package = %{shipment.package | container: :box_large, insurance: nil}
      shipment = %{shipment | package: package}
      {:ok, rate1} = USPS.fetch_rate(shipment, :usps_priority)

      package = %{shipment.package | container: :box_large, insurance: 1000_00}
      shipment = %{shipment | package: package}
      {:ok, rate2} = USPS.fetch_rate(shipment, :usps_priority)

      assert rate1.price < rate2.price
    end
  end

  describe "international" do
    setup do
      [shipment: Helper.valid_shipment(to: "CA")]
    end

    test "rates generated", %{shipment: shipment} do
      package = %{shipment.package | container: :variable}
      shipment = %{shipment | package: package}
      assert USPS.fetch_rate(shipment, :usps_priority)
    end

    test "rates generated with insurance", %{shipment: shipment} do
      package = %{shipment.package | container: :variable, insurance: nil}
      shipment = %{shipment | package: package}
      {:ok, rate1} = USPS.fetch_rate(shipment, :usps_priority)

      package = %{shipment.package | container: :variable, insurance: 200_00}
      shipment = %{shipment | package: package}
      {:ok, rate2} = USPS.fetch_rate(shipment, :usps_priority)

      # International priority shipments come with $200 insured
      assert rate1.price == rate2.price

      package = %{shipment.package | container: :variable, insurance: 300_00}
      shipment = %{shipment | package: package}
      {:ok, rate3} = USPS.fetch_rate(shipment, :usps_priority)

      assert rate2.price < rate3.price
    end
  end

  # Generate a test for every country
  for {code, full} <- ISO.countries(), code != "US" do
    @tag String.to_atom(code)
    @code code
    @full full
    @prefix if not USPS.domestic?(code), do: "international", else: "domestic"
    test "#{@prefix} rates generated for country #{@code} #{@full}" do
      shipment =
        Shippex.Shipment.new!(Helper.origin(), Helper.destination(@code), Helper.package())

      shipment = %{shipment | package: %{shipment.package | container: :variable}}

      rate = USPS.fetch_rate(shipment, :usps_priority)

      if Shippex.services_country?(:usps, @code) do
        assert {:ok, _rate} = rate
      else
        assert {:error, %{message: _}} = rate
      end
    end
  end
end
