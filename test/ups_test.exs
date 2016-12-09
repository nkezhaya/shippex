defmodule UPSTest do
  use ExUnit.Case
  doctest Shippex

  setup do
    origin = %Shippex.Address{
      name: "Earl G",
      phone: "123-123-1234",
      address: "9999 Hobby Lane",
      address_line_2: nil,
      city: "Austin",
      state: "TX",
      zip: "78703"
    }

    destination = %Shippex.Address{
      name: "Bar Baz",
      phone: "123-123-1234",
      address: "1234 Foo Blvd",
      address_line_2: nil,
      city: "Plano",
      state: "TX",
      zip: "75074"
    }

    package = %Shippex.Package{
      length: 8,
      width: 8,
      height: 4,
      weight: 5,
      description: "Headphones"
    }

    shipment = %Shippex.Shipment{
      from: origin,
      to: destination,
      package: package
    }

    [shipment: shipment]
  end

  test "rates generated, label fetched", %{shipment: shipment} do
    # Fetch rates
    {:ok, rates} = Shippex.Carriers.UPS.fetch_rates(shipment)

    assert rates

    # Accept one of the services and print the label
    {:ok, rate} = Enum.shuffle(rates) |> hd

    {:ok, label} = rate
    |> Shippex.Carriers.UPS.fetch_label(shipment)

    assert label
  end
end
