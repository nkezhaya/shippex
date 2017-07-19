ExUnit.start()

defmodule Helper do
  def valid_shipment do
    origin = Shippex.Address.to_struct(%{
      name: "Earl G",
      phone: "123-123-1234",
      address: "9999 Hobby Lane",
      address_line_2: nil,
      city: "Austin",
      state: "TX",
      zip: "78703"
    })

    destination = Shippex.Address.to_struct(%{
      name: "Bar Baz",
      phone: "123-123-1234",
      address: "404 S Figueroa St",
      address_line_2: nil,
      city: "Los Angeles",
      state: "CA",
      zip: "90071"
    })

    %Shippex.Shipment{
      from: origin,
      to: destination,
      package: package()
    }
  end

  defp package() do
    %Shippex.Package{
      length: 8,
      width: 8,
      height: 4,
      weight: 5,
      description: "Headphones",
      monetary_value: 20
    }
  end
end
