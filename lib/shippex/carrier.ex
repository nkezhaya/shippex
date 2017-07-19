defmodule Shippex.Carrier do
  @moduledoc false

  @type t :: atom

  @spec carrier_module(atom) :: module()
  def carrier_module(:ups), do: Shippex.Carrier.UPS
  def carrier_module(:usps), do: Shippex.Carrier.USPS
end
