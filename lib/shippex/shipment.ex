defmodule Shippex.Shipment do
  @moduledoc """
  A `Shipment` represents everything needed to fetch rates from carriers: an
  origin, a destination, and a package description. An optional `:id` field
  is provided in the struct, which may be used by the end user to represent the
  user's internal identifier for the shipment.
  """

  alias Shippex.{Shipment, Address}

  @type t :: %__MODULE__{}

  @enforce_keys [:from, :to, :package]
  defstruct [:id, :from, :to, :package]

  @doc """
  Returns whether or not the shipment is international. Simply compares the
  origin and destination countries.
  """
  @spec international?(Shipment.t) :: boolean
  def international?(%Shipment{from: %Address{country: origin},
                               to: %Address{country: destination}}) do
    origin != destination
  end
end
