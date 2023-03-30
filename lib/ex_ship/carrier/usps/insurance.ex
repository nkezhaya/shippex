defmodule ExShip.Carrier.USPS.Insurance do
  @moduledoc """
  This is a module that holds insurance related functions
  """

  defstruct codes: [
              default: 100,
              usps_gxg: 106,
              usps_priority: 108,
              usps_priority_express: 107,
              usps_priority: 125,
              usps_priority_express: 101
            ]

  def code(%{id: atom}), do: Keyword.get(__MODULE__, atom, 100)
end
