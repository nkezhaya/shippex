defmodule Shippex do
  @moduledoc """
  ## Configuration

      config :shippex,
        env: :dev,
        carriers: [
          ups: [
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
              zip: "78999"
            }
          ]
        ]

  ## Create origin/destination addresses

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
        address: "1234 Foo Blvd",
        address_line_2: nil,
        city: "Plano",
        state: "TX",
        zip: "75074"
      })

  ## Create a package

      # Currently only inches and pounds (lbs) supported.
      package = %Shippex.Package{
        length: 8,
        width: 8,
        height: 4,
        weight: 5,
        description: "Headphones"
      }

  ## Link the origin, destination, and package with a Shipment

      shipment = %Shippex.Shipment{
        from: origin,
        to: destination,
        package: package
      }

  ## Fetch rates to present to the user.

      rates = Shippex.fetch_rates(shipment)

  ## Accept one of the services and print the label

      {:ok, rate} = Enum.shuffle(rates) |> hd
      {:ok, label} = Shippex.fetch_label(rate, shipment)

  ## Write the label gif to disk

      File.write!("\#{label.tracking_number}.gif", Base.decode64!(label.image))
  """

  @type response :: %{code: String.t, message: String.t}

  defmodule InvalidConfigError do
    defexception [:message]

    def exception(message) do
      "Invalid config: #{inspect message}"
    end
  end

  @doc false
  def config do
    case Application.get_env(:shippex, :carriers, :not_found) do
      :not_found -> raise InvalidConfigError, "Shippex config not found"

      config -> config
    end
  end

  @doc """
  Provides a method of returning all available carriers. This is based on
  the config and does not include validation.

      Shippex.carriers #=> [:ups]
  """
  @spec carriers() :: [atom]
  def carriers do
    cfg = Shippex.config()

    ups   = if Keyword.get(cfg, :ups),    do: :ups
    fedex = if Keyword.get(cfg, :fedex),  do: :fedex
    usps  = if Keyword.get(cfg, :usps),   do: :usps

    Enum.filter [ups, fedex, usps], fn (c) -> not is_nil(c) end
  end

  @doc """
  Fetches the env atom for the config. Must be either `:dev` or `:prod`, or an
  exception will be thrown.

      config :shippex, :env, :dev

      Shippex.env #=> :dev
  """
  @spec env() :: atom
  def env do
    case Application.get_env(:shippex, :env, :dev) do
      e when e in [:dev, :prod] -> e
      _ -> raise InvalidConfigError, "Shippex env must be either :dev or :prod"
    end
  end

  @doc """
  Fetches rates from `carriers` for a given `Shipment`.
  """
  @spec fetch_rates(Shipment.t, [atom]) :: [{atom, Rate.t}]
  def fetch_rates(%Shippex.Shipment{} = shipment, carriers \\ :all) do
    # Convert the atom to a list if necessary.
    carriers = cond do
      is_nil(carriers)  -> [:all]
      is_atom(carriers) -> [carriers]
      is_list(carriers) -> carriers

      true ->
        raise """
        #{inspect carriers} is an invalid carrier or list of carriers. Try using an atom. For example:

          Shippex.fetch_rates(shipment, :ups)
        """
    end

    # Validate each carrier.
    available_carriers = Shippex.carriers()
    Enum.each carriers, fn (carrier) ->
      unless Enum.any?(available_carriers, fn (c) -> c == carrier end) do
        raise "#{inspect carrier} not found in #{inspect available_carriers}"
      end
    end

    # TODO
    rates  = Shippex.Carrier.UPS.fetch_rates(shipment)
    oks    = Enum.filter rates, &(elem(&1, 0) == :ok)
    errors = Enum.filter rates, &(elem(&1, 0) == :error)

    Enum.sort(oks, fn (r1, r2) ->
      {:ok, r1} = r1
      {:ok, r2} = r2

      r1.price < r2.price
    end) ++ errors
  end

  @doc """
  Fetches the rate for `shipment` for a specific `Service`. The `service` module
  contains the `Carrier` and selected delivery speed.

      Shippex.fetch_rate(shipment, service)
  """
  @spec fetch_rate(Shipment.t, Service.t) :: {atom, Rate.t}
  def fetch_rate(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    Shippex.Carrier.UPS.fetch_rate(shipment, service)
  end

  @doc """
  Fetches the label for `shipment` for a specific `Service`. The `service`
  module contains the `Carrier` and selected delivery speed.

      Shippex.fetch_label(shipment, service)
  """
  @spec fetch_label(Shipment.t, Service.t) :: {atom, Label.t}
  def fetch_label(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    Shippex.Carrier.UPS.fetch_label(shipment, service)
  end

  @doc """
  Cancels the shipment associated with `label`, if possible. The result is
  returned in a tuple.

  You may pass in either the label or tracking number.

      case Shippex.cancel_shipment(label) do
        {:ok, result} ->
          IO.inspect(result) #=> %{code: "1", message: "Voided successfully."}
        {:error, %{code: code, message: message}} ->
          IO.inspect(code)
          IO.inspect(message)
      end
  """
  @spec cancel_shipment(Label.t | String.t) :: {atom, response}
  def cancel_shipment(%Shippex.Label{} = label) do
    Shippex.Carrier.UPS.cancel_shipment(label.tracking_number)
  end
  def cancel_shipment(tracking_number) when is_bitstring(tracking_number) do
    Shippex.Carrier.UPS.cancel_shipment(tracking_number)
  end

  @doc """
  Performs address validation. If the address is completely invalid,
  `{:error, result}` is returned. For addresses that may have typos,
  `{:ok, candidates}` is returned. You can iterate through the list of
  candidates to present to the end user. Addresses that pass validation
  perfectly will still be in a `list` where `length(candidates) == 1`.

  Note that the `candidates` returned will automatically pass through
  `Shippex.Address.to_struct()` for casting.

      address = Shippex.Address.to_struct(%{
        name: "Earl G",
        phone: "123-123-1234",
        address: "9999 Hobby Lane",
        address_line_2: nil,
        city: "Austin",
        state: "TX",
        zip: "78703"
      })

      case Shippex.validate_address(address) do
        {:error, %{code: code, message: message}} ->
          # Present the error.
        {:ok, candidates} ->
          if length(candidates) == 1 do
            # Use the address
          else
            # Present candidates to user for selection
          end
      end
  """
  @spec validate_address(Address.t) :: {atom, response | [Address.t]}
  def validate_address(%Shippex.Address{} = address) do
    Shippex.Carrier.UPS.validate_address(address)
  end
end
