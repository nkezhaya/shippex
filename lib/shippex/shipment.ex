defmodule Shippex.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a package description. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment. The id is not used by Shippex.

  Shipments are created by `shipment/3`.
  """

  alias Shippex.{Shipment, Address, Package}

  @enforce_keys [:from, :to, :package, :ship_date]
  defstruct [:id, :from, :to, :package, :ship_date]

  @type t :: %__MODULE__{
          id: any(),
          from: Address.t(),
          to: Address.t(),
          package: Package.t(),
          ship_date: any()
        }

  @doc """
  Builds a `Shipment`.
  """
  @spec new(Address.t(), Address.t(), Package.t(), Keyword.t()) ::
          {:ok, t()} | {:error, String.t()}
  def new(%Address{} = from, %Address{} = to, %Package{} = package, opts \\ []) do
    ship_date = Keyword.get(opts, :ship_date)

    if from.country != "US" do
      throw({:error, "Shippex does not yet support shipments originating outside of the US."})
    end

    if not (is_nil(ship_date) or match?(%Date{}, ship_date)) do
      throw({:error, "Invalid ship date: #{ship_date}"})
    end

    shipment = %Shipment{
      from: from,
      to: to,
      package: package,
      ship_date: ship_date
    }

    {:ok, shipment}
  catch
    {:error, _} = e -> e
  end

  @doc """
  Builds a `Shipment`. Raises on failure.
  """
  @spec new!(Address.t(), Address.t(), Package.t(), Keyword.t()) :: t() | none()
  def new!(%Address{} = from, %Address{} = to, %Package{} = package, opts \\ []) do
    case new(from, to, package, opts) do
      {:ok, shipment} -> shipment
      {:error, error} -> raise error
    end
  end
end
