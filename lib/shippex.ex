defmodule Shippex do
  @moduledoc """
  ## Configuration

      config :shippex,
        env: :dev,
        distance_unit: :in, # either :in or :cm
        weight_unit: :lbs, # either :lbs or :kg
        currency: :usd, # :usd, :can, :mxn, :eur
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
          ],
          usps: [
            username: "MyUsername",
            password: "MyPassword"
          ]
        ]

  ## Create origin/destination addresses

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

  alias Shippex.{Carrier, Label, Service, Shipment, Transaction}

  @type response :: %{code: String.t(), message: String.t()}

  defmodule InvalidConfigError do
    defexception [:message]

    def exception(message) do
      %InvalidConfigError{message: "Invalid config: #{inspect(message)}"}
    end
  end

  @doc false
  def config() do
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
  @spec carriers() :: [Carrier.t()]
  def carriers() do
    cfg = Shippex.config()

    ups = if Keyword.get(cfg, :ups), do: :ups
    fedex = if Keyword.get(cfg, :fedex), do: :fedex
    usps = if Keyword.get(cfg, :usps), do: :usps

    Enum.reject([ups, fedex, usps], &is_nil/1)
  end

  @doc """
  Returns the configured currency code. Raises an error if an invalid code was
  used.

      config :shippex, :currency, :can

      Shippex.currency_code() #=> "CAN"
  """
  @spec currency_code() :: String.t()
  def currency_code() do
    case Application.get_env(:shippex, :currency, :usd) do
      code when code in [:usd, :can, :mxn] ->
        code |> Atom.to_string() |> String.upcase()

      _ ->
        raise InvalidConfigError, "Shippex currency must be either :usd, :can, or :mxn"
    end
  end

  @doc """
  Fetches the env atom for the config. Must be either `:dev` or `:prod`, or an
  exception will be thrown.

      config :shippex, :env, :dev

      Shippex.env #=> :dev
  """
  @spec env() :: atom
  def env() do
    case Application.get_env(:shippex, :env, :dev) do
      e when e in [:dev, :prod] -> e
      _ -> raise InvalidConfigError, "Shippex env must be either :dev or :prod"
    end
  end

  @doc """
  Fetches rates from `carriers` for a given `Shipment`.
  """
  @spec fetch_rates(Shipment.t(), [Carrier.t()] | nil) :: [{atom, Rate.t()}]
  def fetch_rates(%Shipment{} = shipment, carriers \\ nil) do
    # Convert the atom to a list if necessary.
    carriers =
      cond do
        is_nil(carriers) ->
          Shippex.carriers()

        is_atom(carriers) ->
          [carriers]

        is_list(carriers) ->
          carriers

        true ->
          raise """
          #{inspect(carriers)} is an invalid carrier or list of carriers.
          Try using an atom. For example:

              Shippex.fetch_rates(shipment, :ups)
          """
      end
      |> Enum.map(&Shippex.Carrier.module/1)

    rates = Enum.reduce(carriers, [], &(&1.fetch_rates(shipment) ++ &2))
    oks = Enum.filter(rates, &(elem(&1, 0) == :ok))
    errors = Enum.filter(rates, &(elem(&1, 0) == :error))

    Enum.sort(oks, fn r1, r2 ->
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
  @spec fetch_rate(Shipment.t(), Service.t()) :: {atom, Rate.t()}
  def fetch_rate(%Shipment{} = shipment, %Service{carrier: carrier} = service) do
    case Carrier.module(carrier).fetch_rate(shipment, service) do
      [rate] -> rate
      {_, _} = rate -> rate
    end
  end

  @doc """
  Fetches the label for `shipment` for a specific `Service`. The `service`
  module contains the `Carrier` and selected delivery speed.

      Shippex.create_transaction(shipment, service)
  """
  @spec create_transaction(Shipment.t(), Service.t()) :: {atom, Label.t()}
  def create_transaction(%Shipment{} = shipment, %Service{carrier: carrier} = service) do
    Carrier.module(carrier).create_transaction(shipment, service)
  end

  @doc """
  Cancels the transaction associated with `label`, if possible. The result is
  returned in a tuple.

  You may pass in either the transaction, or if the full transaction struct
  isn't available, you may pass in the carrier, shipment, and tracking number
  instead.

      case Shippex.cancel_shipment(transaction) do
        {:ok, result} ->
          IO.inspect(result) #=> %{code: "1", message: "Voided successfully."}
        {:error, %{code: code, message: message}} ->
          IO.inspect(code)
          IO.inspect(message)
      end
  """
  @spec cancel_transaction(Transaction.t()) :: {atom, response}
  @spec cancel_transaction(Carrier.t(), Shipment.t(), String.t()) :: {atom, response}
  def cancel_transaction(%Transaction{} = transaction) do
    Carrier.module(transaction.carrier).cancel_transaction(transaction)
  end

  def cancel_transaction(carrier, %Shipment{} = shipment, tracking_number) do
    Carrier.module(carrier).cancel_transaction(shipment, tracking_number)
  end

  @doc """
  Performs address validation. If the address is completely invalid,
  `{:error, result}` is returned. For addresses that may have typos,
  `{:ok, candidates}` is returned. You can iterate through the list of
  candidates to present to the end user. Addresses that pass validation
  perfectly will still be in a `list` where `length(candidates) == 1`.

  Note that the `candidates` returned will automatically pass through
  `Shippex.Address.address()` for casting. Also, if `:usps` is used as the
  validation provider, the number of candidates will always be 1.

      address = Shippex.Address.address(%{
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
        {:ok, candidates} when length(candidates) == 1 ->
          # Use the address
        {:ok, candidates} when length(candidates) > 1 ->
          # Present candidates to user for selection
      end
  """
  @spec validate_address(Address.t(), Keyword.t()) :: {atom, response | [Address.t()]}
  def validate_address(%Shippex.Address{} = address, opts \\ []) do
    carrier = Keyword.get(opts, :carrier, :usps)

    case address.country do
      "US" ->
        Carrier.module(carrier).validate_address(address)

      country ->
        case Shippex.Util.states(country)[address.state] do
          nil ->
            {:error, %{code: "0", description: "State does not belong to country."}}

          _ ->
            {:ok, [address]}
        end
    end
  end
end
