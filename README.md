# Shippex

Shippex is an abstraction of commonly used features in shipping with various carriers. It provides a (hopefully) pleasant API to work with carrier-provided web interfaces for fetching rates and printing shipping labels.

As of now, only UPS and USPS are supported. More carrier support will come in the future. Units of measurement are mostly hardcoded to inches and miles.

## Installation

1. Add `shippex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:shippex, "~> 0.4.0"}]
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
origin = Shippex.Address.address(%{
  name: "Earl G",
  phone: "123-123-1234",
  address: "9999 Hobby Lane",
  address_line_2: nil,
  city: "Austin",
  state: "TX",
  zip: "78703"
})

destination = Shippex.Address.address(%{
  name: "Bar Baz",
  phone: "123-123-1234",
  address: "1234 Foo Blvd",
  address_line_2: nil,
  city: "Plano",
  state: "TX",
  zip: "75074",
  country: "US" # optional
})

package = %Shippex.Package{
  length: 8,
  width: 8,
  height: 4,
  weight: 5,
  description: "Headphones",
  monetary_value: 20 # optional
}

shipment = %Shippex.Shipment{
  from: origin,
  to: destination,
  package: package
}

# Fetch rates
rates = Shippex.fetch_rates(shipment)

# Accept one of the services and print the label
{:ok, rate} = Enum.shuffle(rates) |> hd

# Fetch the label. Includes the tracking number and a gif image of the label.
{:ok, label} = Shippex.fetch_label(rate, shipment)

# Write the label to disk.
File.write!("#{label.tracking_number}.#{label.format}",
            Base.decode64!(label.image))
```

## TODO:

Carrier support:

- [x] UPS
- [x] USPS
- [ ] FedEx

Country support:

- [x] US
- [x] Canada
- [x] Mexico
- [ ] Puerto Rico
- [ ] Virgin Islands
- [ ] US territories
- [ ] European Union
- [ ] Poland
