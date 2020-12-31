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
      state: "US-TX",
      postal_code: "78722"
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
      state: "US-MO",
      postal_code: "63966"
    })
  end

  def destination("CA") do
    Shippex.Address.new!(%{
      first_name: "Some",
      last_name: "Person",
      phone: "778-123-1234",
      address: "4575 Clancy Loranger Way",
      city: "Vancouver",
      state: "CA-BC",
      postal_code: "V5Y 2M4",
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
      state: "MX-CMX",
      postal_code: "03100",
      country: "MX"
    })
  end

  def destination(country) when is_binary(country) do
    state =
      with true <- Shippex.Address.subdivision_required?(country),
           {_, %{"subdivisions" => subdivisions}} <- ISO.find_country(country),
           [sub | _] <- subdivisions do
        sub
      else
        _ -> nil
      end

    {city, postal_code} = city_postal_code(country)

    Shippex.Address.new!(%{
      first_name: "Some",
      last_name: "Person",
      phone: "778-123-1234",
      address: "4575 Random Address Rd",
      city: city,
      state: state,
      postal_code: postal_code,
      country: country
    })
  end

  def destination(%Shippex.Address{} = address), do: address

  defp city_postal_code("AS"), do: {"Pago Pago", "96799"}
  defp city_postal_code("GU"), do: {"Hagatna", "96910"}
  defp city_postal_code("FM"), do: {"Chuuk", "96942"}
  defp city_postal_code("MH"), do: {"Majuro", "96970"}
  defp city_postal_code("MP"), do: {"Saipan", "96950"}
  defp city_postal_code("PR"), do: {"San Juan", "00921"}
  defp city_postal_code("PW"), do: {"Ngerulmud", "96939"}
  defp city_postal_code("VI"), do: {"Cruz Bay", "00830"}
  defp city_postal_code(_), do: {"City", "00000"}

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
