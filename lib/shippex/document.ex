defmodule Shippex.Document do
  @moduledoc """
  A `Pickup` represents everything needed to manage a pickup.

  Pickups are created by `pickup/3`.
  """

  alias Shippex.{Document, Address, Package}

  @enforce_keys [:from, :to,  :pickup_date, :packages, :params]
  defstruct [:id, :from, :to, :pickup_date, :packages, :params]

  @type t :: %__MODULE__{
          id: any(),
          from: Address.t(),
          to: Address.t(),
          packages: List.t(),
          pickup_date: any(),
          params: any()
        }

end
