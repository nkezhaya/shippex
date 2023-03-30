defmodule ExShip.UPS.RateTest do
  use ExUnit.Case

  alias ExShip.Carrier.UPS

  # Generate a test for every country
  for {code, %{"name" => full}} <- ISO.countries(), code in ~w(CA MX) do
    @tag String.to_atom(code)
    @code code
    @full full
    test "rates generated for country #{@code} #{@full}" do
      shipment =
        ExShip.Shipment.new!(Helper.origin(), Helper.destination(@code), Helper.package())

      shipment = %{shipment | package: %{shipment.package | container: :variable}}

      for rate <- UPS.fetch_rates(shipment) do
        if ExShip.services_country?(:ups, @code) do
          assert {:ok, _rate} = rate
        else
          assert {:error, %{message: _}} = rate
        end
      end
    end
  end
end
