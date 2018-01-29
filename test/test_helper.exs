ExUnit.start()

defmodule Helper do
  def valid_shipment do
    origin = Shippex.Address.address(%{
      name: "Jimmy",
      phone: "213-624-2378",
      address: "3209 French Pl",
      address_line_2: nil,
      city: "Austin",
      state: "TX",
      zip: "78722"
    })

    destination = Shippex.Address.address(%{
      name: "Charlie",
      phone: "646-473-0204",
      address: "192 Rainbird Lane",
      address_line_2: nil,
      city: "Wappapello",
      state: "MO",
      zip: "63966"
    })

    Shippex.Shipment.shipment(origin, destination, package())
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
