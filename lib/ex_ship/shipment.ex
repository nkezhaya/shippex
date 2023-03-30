defmodule ExShip.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a list of packages. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment. The id is not used by ExShip.

  Shipments are created by `shipment/3`.
  """

  alias ExShip.{Shipment, Address}

  @enforce_keys [:from, :to, :ship_date, :packages, :params]
  defstruct [:id, :from, :to, :ship_date, :packages, :params]

  @type t :: %__MODULE__{
          id: any(),
          from: Address.t(),
          to: Address.t(),
          packages: List.t(),
          ship_date: any(),
          params: any()
        }

  @doc """
  Builds a `Shipment`.
  """
  @spec new(Address.t(), Address.t(), List.t(), Keyword.t()) ::
          {:ok, t()} | {:error, String.t()}
  def new(%Address{} = from, %Address{} = to, packages, opts \\ []) when is_list(packages) do
    ship_date = Keyword.get(opts, :ship_date)
    params = Keyword.get(opts, :params)

    if from.country != "US" do
      throw({:error, "ExShip does not yet support shipments originating outside of the US."})
    end

    if not (is_nil(ship_date) or match?(%Date{}, ship_date)) do
      throw({:error, "Invalid ship date: #{ship_date}"})
    end

    shipment = %Shipment{
      from: from,
      to: to,
      packages: packages,
      ship_date: ship_date,
      params: params
    }

    {:ok, shipment}
  catch
    {:error, _} = e -> e
  end

  def new(%Address{} = from, %Address{} = to, package, opts) do
    new(from, to, [package], opts)
    end

  @doc """
  Builds a `Shipment`. Raises on failure.
  """
  @spec new!(Address.t(), Address.t(), List.t(), Keyword.t()) :: t() | none()
  def new!(%Address{} = from, %Address{} = to, [] = packages, opts \\ []) when is_list(packages) do
    case new(from, to, packages, opts) do
      {:ok, shipment} -> shipment
      {:error, error} -> raise error
    end
  end

  def new!(from,to, package, opts ) do
    new!(from, to, [package], opts)
  end

end
