ExUnit.start()

defmodule Helper do
  def valid_shipment(opts \\ []) do
    to = Keyword.get(opts, :to, "US")
    insurance = Keyword.get(opts, :insurance)
    Shippex.Shipment.shipment(origin(), destination(to), package(insurance))
  end

  def origin() do
    Shippex.Address.new!(%{
      first_name: "Jimmy",
      last_name: "Go",
      phone: "213-624-2378",
      address: "3209 French Pl",
      address_line_2: nil,
      city: "Austin",
      state: "TX",
      zip: "78722"
    })
  end

  def destination(country \\ "US")

  def destination("US") do
    Shippex.Address.new!(%{
      first_name: "Charlie",
      last_name: "Foo",
      phone: "646-473-0204",
      address: "192 Rainbird Lane",
      address_line_2: nil,
      city: "Wappapello",
      state: "MO",
      zip: "63966"
    })
  end

  def destination("CA") do
    Shippex.Address.new!(%{
      first_name: "Some",
      last_name: "Person",
      phone: "778-123-1234",
      address: "4575 Clancy Loranger Way",
      city: "Vancouver",
      state: "BC",
      zip: "V5Y 2M4",
      country: "CA"
    })
  end

  def destination("MX") do
    Shippex.Address.new!(%{
      first_name: "Mexico",
      last_name: "Mexico",
      phone: "123-123-1234",
      address: "Ferrol 4",
      city: "Ciudad de México",
      state: "DIF",
      zip: "03100",
      country: "MX"
    })
  end

  def package(insurance \\ nil) do
    Shippex.Package.new(%{
      length: 8,
      width: 8,
      height: 4,
      weight: 3,
      description: "Headphones",
      monetary_value: 20_00,
      insurance: insurance
    })
  end
end
