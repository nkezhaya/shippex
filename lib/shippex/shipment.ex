defmodule Shippex.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a package description. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment. The id is not used by Shippex.

  Shipments are created by `shipment/3`.
  """

  alias Shippex.{Shipment, Address, Package}

  @type t :: %__MODULE__{}

  @enforce_keys [:from, :to, :package, :ship_date, :international?]
  defstruct [:id, :from, :to, :package, :ship_date, :international?]

  @doc """
  Builds a `Shipment`.
  """
  @spec shipment(Address.t, Address.t, Package.t, Keyword.t) :: t
  def shipment(%Address{} = from, %Address{} = to, %Package{} = package, opts \\ []) do
    intl = from.country != to.country
    ship_date = Keyword.get(opts, :ship_date)

    if from.country != "US" do
      raise "Shippex does not yet support shipments originating outside of the US."
    end

    if not(is_nil(ship_date) or match?(%Date{}, ship_date)) do
      raise "Invalid ship date: #{ship_date}"
    end

    %Shipment{from: from,
              to: to,
              package: package,
              ship_date: ship_date,
              international?: intl}
  end
end
