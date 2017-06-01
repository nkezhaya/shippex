defmodule Shippex do

  defmodule InvalidConfigError do
    defexception [:message]

    def exception(message) do
      "Invalid config: #{inspect message}"
    end
  end

  @doc """
  Fetches the Shippex config for all carriers.

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
  """
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
  def env do
    case Application.get_env(:shippex, :env, :dev) do
      e when e in [:dev, :prod] -> e
      _ -> raise InvalidConfigError, "Shippex env must be either :dev or :prod"
    end
  end

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

  def fetch_rate(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    Shippex.Carrier.UPS.fetch_rate(shipment, service)
  end

  def fetch_label(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    Shippex.Carrier.UPS.fetch_label(shipment, service)
  end

  def cancel_shipment(%Shippex.Label{} = label) do
    Shippex.Carrier.UPS.cancel_shipment(label.tracking_number)
  end
  def cancel_shipment(tracking_number) when is_bitstring(tracking_number) do
    Shippex.Carrier.UPS.cancel_shipment(tracking_number)
  end

  def validate_address(%Shippex.Address{} = address) do
    Shippex.Carrier.UPS.validate_address(address)
  end
end
