ExUnit.start()
ExUnit.configure(exclude: [skip: true])

defmodule Helper do
  def valid_shipment(opts \\ []) do
    to = Keyword.get(opts, :to, "US")
    insurance = Keyword.get(opts, :insurance)
    Shippex.Shipment.new!(origin(), destination(to), package(insurance))
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
      state: "CMX",
      zip: "03100",
      country: "MX"
    })
  end

  def destination(country) when is_binary(country) do
    state =
      if Shippex.Address.subdivision_required?(country) do
        {_, %{"subdivisions" => subdivisions}} = Shippex.ISO.find_country(country)
        Map.keys(subdivisions) |> hd()
      else
        nil
      end

    {city, zip} = city_zip(country)

    Shippex.Address.new!(%{
      first_name: "Some",
      last_name: "Person",
      phone: "778-123-1234",
      address: "4575 Random Address Rd",
      city: city,
      state: state,
      zip: zip,
      country: country
    })
  end

  def destination(%Shippex.Address{} = address), do: address

  defp city_zip("AS"), do: {"Pago Pago", "96799"}
  defp city_zip("GU"), do: {"Hagatna", "96910"}
  defp city_zip("FM"), do: {"Chuuk", "96942"}
  defp city_zip("MH"), do: {"Majuro", "96970"}
  defp city_zip("MP"), do: {"Saipan", "96950"}
  defp city_zip("PR"), do: {"San Juan", "00921"}
  defp city_zip("PW"), do: {"Ngerulmud", "96939"}
  defp city_zip("VI"), do: {"Cruz Bay", "00830"}
  defp city_zip(_), do: {"City", "00000"}

  def package(insurance \\ nil) do
    Shippex.Package.new(%{
      length: 8,
      width: 8,
      height: 4,
      insurance: insurance,
      items: [
        %{
          weight: 3,
          description: "Headphones",
          monetary_value: 20_00
        },
        %{
          weight: 1,
          description: "Small headphones",
          monetary_value: 40_00
        }
      ]
    })
  end
end
