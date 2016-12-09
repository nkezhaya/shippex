# Shippex

Shippex is an abstraction of commonly used features in shipping with various carriers. It provides a (hopefully) pleasant API to work with carrier-provided web interfaces for fetching rates and printing shipping labels.

As of now, only UPS is supported. More carrier support will come in the future. Units of measurement are currently hardcoded to inches and miles.

## Installation

  1. Add `shippex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:shippex, "~> 0.1.0"}]
    end
    ```

  2. Ensure `shippex` is started before your application:

    ```elixir
    def application do
      [applications: [:shippex]]
    end
    ```

## Fetching rates

```elixir
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

# Fetch rates
rates = Shippex.Carriers.UPS.fetch_rates(shipment)

# Accept one of the services and print the label
{:ok, rate} = Enum.shuffle(rates) |> hd

# Fetch the label. Includes the tracking number and a gif image of the label.
{:ok, label} = rate
|> Shippex.Carriers.UPS.fetch_label(shipment)

# Write the label to disk.
File.write!("#{label.tracking_number}.gif", Base.decode64!(label.image))
```
