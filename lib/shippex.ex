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
        description: "Headphones",
        monetary_value: 20 # optional
      }

  ## Link the origin, destination, and package with a Shipment

      shipment = Shippex.Shipment.shipment(origin, destination, package)

  ## Fetch rates to present to the user.

      rates = Shippex.fetch_rates(shipment, carriers: [:usps, :ups])

  ## Accept one of the services and print the label

      {:ok, rate} = Enum.shuffle(rates) |> hd
      {:ok, transaction} = Shippex.create_transaction(shipment, rate.service)
      label = transaction.label

  ## Write the label gif to disk

      File.write!("\#{label.tracking_number}.gif", Base.decode64!(label.image))
  """

  alias Shippex.{Address, Carrier, Config, Rate, Service, Shipment, Transaction}

  @type response() :: %{code: String.t(), message: String.t()}

  @doc """
  Fetches rates for a given `shipment`. Possible options:

    * `carriers` - Fetches rates for *all* services for the given carriers
    * `services` - Fetches rates only for the given services

  These may be used in combination. To fetch rates for *all* UPS services, as
  well as USPS Priority, for example:

      Shippex.fetch_rates(shipment, carriers: :ups, services: [:usps_priority])

  If no options are provided, Shippex will fetch rates for every service from
  every available carrier.
  """
  @spec fetch_rates(Shipment.t(), Keyword.t()) :: [{atom, Rate.t()}]
  def fetch_rates(%Shipment{} = shipment, opts \\ []) do
    # Convert the atom to a list if necessary.
    carriers = Keyword.get(opts, :carriers)
    services = Keyword.get(opts, :services)

    carriers =
      if is_nil(carriers) and is_nil(services) do
        Shippex.carriers()
      else
        cond do
          is_nil(carriers) ->
            []

          is_atom(carriers) ->
            [carriers]

          is_list(carriers) ->
            carriers

          true ->
            raise """
            #{inspect(carriers)} is an invalid carrier or list of carriers.
            Try using an atom. For example:

                Shippex.fetch_rates(shipment, carriers: :usps)
            """
        end
      end

    services =
      case services do
        nil ->
          []

        service when is_atom(service) ->
          [service]

        services when is_list(services) ->
          services

        services ->
          raise """
          #{inspect(services)} is an invalid service or list of services.
          Try using an atom. For example:

              Shippex.fetch_rates(shipment, services: :usps_priority)
          """
      end
      |> Enum.reject(&(Service.get(&1).carrier in carriers))

    carrier_tasks =
      Enum.map(carriers, fn carrier ->
        Task.async(fn ->
          Carrier.module(carrier).fetch_rates(shipment)
        end)
      end)

    service_tasks =
      Enum.map(services, fn service ->
        Task.async(fn ->
          fetch_rate(shipment, service)
        end)
      end)

    rates =
      (carrier_tasks ++ service_tasks)
      |> Task.yield_many(5000)
      |> Enum.map(fn {task, rates} ->
        rates || Task.shutdown(task, :brutal_kill)
      end)
      |> Enum.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, rates} -> rates end)
      |> List.flatten()
      |> Enum.reject(fn
        {atom, _} -> not (atom in [:ok, :error])
        _ -> true
      end)

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
  contains the `Carrier` and selected delivery speed. You can also pass in the
  ID of the service.

      Shippex.fetch_rate(shipment, service)
  """
  @spec fetch_rate(Shipment.t(), atom() | Service.t()) :: {atom, Rate.t()}
  def fetch_rate(%Shipment{} = shipment, service) when is_atom(service) do
    service = Service.get(service)
    fetch_rate(shipment, service)
  end

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
  @spec create_transaction(Shipment.t(), Service.t()) ::
          {:ok, Transaction.t()} | {:error, response}
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
  def cancel_transaction(%Transaction{} = transaction) do
    Carrier.module(transaction.carrier).cancel_transaction(transaction)
  end

  @spec cancel_transaction(Carrier.t(), Shipment.t(), String.t()) :: {atom, response}
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
  @spec validate_address(Address.t(), Keyword.t()) :: {atom(), response() | [Address.t()]}
  defdelegate validate_address(address, opts \\ []), to: Address, as: :validate

  @doc false
  defdelegate json_library(), to: Config

  @doc false
  defdelegate carriers(), to: Config

  @doc false
  defdelegate currency_code(), to: Config

  @doc false
  defdelegate env(), to: Config
end
