defmodule Shippex.Pickup do
  @moduledoc """
  A `Pickup` represents everything needed to manage a pickup.

  Pickups are created by `pickup/3`.
  """

  alias Shippex.{Pickup, Address, Parcel}

  @enforce_keys [:from, :to,  :pickup_date, :parcels, :params]
  defstruct [:id, :from, :to, :pickup_date, :parcels, :params]

  @type t :: %__MODULE__{
          id: any(),
          from: Address.t(),
          to: Address.t(),
          parcels: List.t(),
          pickup_date: any(),
          params: any()
        }

end
