defmodule Shippex.Carrier do
  @moduledoc """
  Defines a behaviour for implementing a new Carrier module. Includes a helper
  function for fetching the Carrier module.
  """

  alias Shippex.Carrier
  alias Shippex.{Shipment, Service, Rate, Transaction}

  @callback fetch_rates(Shipment.t()) :: [{atom, Rate.t()}]
  @callback fetch_rate(Shipment.t(), Service.t()) :: [{atom, Rate.t()}] | {atom, Rate.t()}
  @callback create_transaction(Shipment.t(), atom() | Service.t()) ::
              {atom, Transaction.t() | map}
  @callback cancel_transaction(Transaction.t()) :: {atom, String.t()}
  @callback cancel_transaction(Shipment.t(), String.t()) :: {atom, String.t()}
  @callback validate_address(Address.t()) :: {:ok, [Address.t()]} | {:error, any()}
  @callback track_packages(String.t() | [String.t()]) :: {:ok | :error, any()}
  @callback services_country?(ISO.country_code()) :: boolean()

  @type t() :: atom()

  @doc """
  Fetches a Carrier module by its atom/string representation.

      iex> Carrier.module(:ups)
      Carrier.UPS
      iex> Carrier.module("UPS")
      Carrier.UPS
      iex> Carrier.module("ups")
      Carrier.UPS
  """
  @spec module(atom | String.t()) :: module()
  def module(carrier) when is_atom(carrier) do
    # NOTE, this might be a good place to use a protocol?
    module =
      case carrier do
        :ups -> Carrier.UPS
        :usps -> Carrier.USPS
        :dummy -> Carrier.Dummy
        c -> raise "#{c} is not a supported carrier at this time."
      end

    available_carriers = Shippex.carriers()

    if carrier in available_carriers do
      module
    else
      raise Shippex.InvalidConfigError,
            "#{inspect(carrier)} not found in carriers: #{inspect(available_carriers)}"
    end
  end

  def module(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.to_atom()
    |> module
  end
end
