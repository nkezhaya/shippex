defmodule Shippex.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a list of parcels. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment. The id is not used by Shippex.

  Shipments are created by `shipment/3`.
  """

  alias Shippex.{Shipment, Address}

  @enforce_keys [:from, :to, :ship_date, :parcels, :params]
  defstruct [:id, :from, :to, :ship_date, :parcels, :params]

  @type t :: %__MODULE__{
          id: any(),
          from: Address.t(),
          to: Address.t(),
          parcels: List.t(),
          ship_date: any(),
          params: any()
        }

  @doc """
  Builds a `Shipment`.
  """
  @spec new(Address.t(), Address.t(), List.t(), Keyword.t()) ::
          {:ok, t()} | {:error, String.t()}
  def new(%Address{} = from, %Address{} = to, parcels \\ [], opts \\ []) do
    ship_date = Keyword.get(opts, :ship_date)
    params = Keyword.get(opts, :params)

    if from.country != "US" do
      throw({:error, "Shippex does not yet support shipments originating outside of the US."})
    end

    if not (is_nil(ship_date) or match?(%Date{}, ship_date)) do
      throw({:error, "Invalid ship date: #{ship_date}"})
    end

    shipment = %Shipment{
      from: from,
      to: to,
      parcels: parcels,
      ship_date: ship_date,
      params: params
    }

    {:ok, shipment}
  catch
    {:error, _} = e -> e
  end

  @doc """
  Builds a `Shipment`. Raises on failure.
  """
  @spec new!(Address.t(), Address.t(), List.t(), Keyword.t()) :: t() | none()
  def new!(%Address{} = from, %Address{} = to, [] = parcels, opts \\ []) do
    case new(from, to, parcels, opts) do
      {:ok, shipment} -> shipment
      {:error, error} -> raise error
    end
  end
end
