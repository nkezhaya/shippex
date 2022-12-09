# Shippex

[![Module Version](https://img.shields.io/hexpm/v/shippex.svg)](https://hex.pm/packages/shippex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/shippex/)
[![Total Download](https://img.shields.io/hexpm/dt/shippex.svg)](https://hex.pm/packages/shippex)
[![License](https://img.shields.io/hexpm/l/shippex.svg)](https://hex.pm/packages/shippex)
[![Last Updated](https://img.shields.io/github/last-commit/whitepaperclip/shippex.svg)](https://github.com/whitepaperclip/shippex/commits/master)

Shippex is an abstraction of commonly used features in shipping with various carriers. It provides a (hopefully) pleasant API to work with carrier-provided web interfaces for fetching rates and printing shipping labels.

As of now, only UPS and USPS are supported. More carrier support will come in the future. Units of measurement are mostly hardcoded to inches and miles.

## Installation

Add `shippex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:shippex, "~> 0.17"}]
end
```

Ensure `shippex` is started before your application:

```elixir
def application do
  [applications: [:shippex]]
end
```

## Configuration

```elixir
config :shippex,
  env: :dev,
  distance_unit: :in, # either :in or :cm
  weight_unit: :lbs, # either :lbs or :kg
  currency: :usd, # :usd, :can, :mxn, :eur
  carriers: [
    ups: [
      module: Shippex.Carrier.UPS, # optional
      username: "MyUsername",
      password: "MyPassword",
      secret_key: "123123",
      shipper: %{
        account_number: "AB1234",
        name: "My Company",
        phone: "123-456-7890",
        address: "1234 Foo St",
        city: "Foo",
        state: "TX",
        postal_code: "78999"
      }
    ],
    usps: [
      module: Shippex.Carrier.USPS,
      username: "MyUsername",
      password: "MyPassword"
    ]
  ]
```

## Usage

```elixir
# set the config after compilation (optional)
carriers_config =  [usps: [module: Shippex.Carrier.USPS, username: "", password: ""]]
# Create origin/destination addresses.
origin = Shippex.Address.new(%{
  name: "Earl G",
  phone: "123-123-1234",
  address: "9999 Hobby Lane",
  address_line_2: nil,
  city: "Austin",
  state: "TX",
  postal_code: "78703"
})

destination = Shippex.Address.new(%{
  name: "Bar Baz",
  phone: "123-123-1234",
  address: "1234 Foo Blvd",
  address_line_2: nil,
  city: "Plano",
  state: "TX",
  postal_code: "75074",
  country: "US" # optional
})

# Create a package. Currently only inches and pounds (lbs) supported.
package = Shippex.Package.new(%{items: [%{
  quantity: 8,
  weight: 45,
  description: "Headphones",
  monetary_value: 20 # optional
}], length: 8,
    width: 8,
    height: 4
})

{:ok, origin} = origin
{:ok, destination} = destination

# Link the origin, destination, and package with a shipment.
shipment = Shippex.Shipment.new(origin, destination, [package])

{:ok, shipment} = shipment

carrier = :usps

## fetch the available shipping methods
services = Shippex.Service.services_for_carrier(carrier, shipment) |> Enum.map(fn(x) -> x.id end)

# Fetch rates to present to the user.
rates = Shippex.fetch_rates(shipment, [carriers: carrier, services: services]) |> Enum.reject(fn({x,_}) -> x == :error end)
# rates = Shippex.fetch_rate(shipment, :usps_retail_ground) 
# Fetch rates to present to the user with carrier config passed at runtime.
#carrier_config = []
#rates = Shippex.fetch_rates(shipment, [carriers: carrier, services: services, carrier_config: carrier_config])

# Accept one of the services and print the label
{:ok, rate} = Enum.shuffle(rates) |> hd

# Fetch the label. Includes the tracking number and a gif image of the label.
{:ok, transaction} = Shippex.create_transaction(shipment, rate.service)

rate = transaction.rate
label = transaction.label

# Print the price.
IO.puts(rate.price)

# Write the label to disk.
File.write!("#{label.tracking_number}.#{label.format}", Base.decode64!(label.image))
```

## Creating your own shipping modules
there are 2 ways of setting up your own shipping module either specifing it in the config if its in its own namespace or
creating a module in your project with following module naming conventions defmodule applicationname.Shippex.Carrier.Modulename, and setting up the config carriers key to match the modules config() return. see the ups module for syntax examples
## TODO:

Carrier support:

- [x] UPS
- [x] USPS
- [ ] FedEx
