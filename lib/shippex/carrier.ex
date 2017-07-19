defmodule Shippex.Carrier do
  @moduledoc false

  @type t :: atom

  @spec carrier_module(atom | String.t) :: module()
  def carrier_module(carrier) when is_atom(carrier) do
    module = case carrier do
      :ups -> Shippex.Carrier.UPS
      :usps -> Shippex.Carrier.USPS
      c -> raise "#{c} is not a supported carrier at this time."
    end

    available_carriers = Shippex.carriers()
    if carrier in available_carriers do
      module
    else
      raise Shippex.InvalidConfigError,
        "#{inspect carrier} not found in carriers: #{inspect available_carriers}"
    end
  end

  def carrier_module(string) when is_bitstring(string) do
    string
    |> String.downcase
    |> String.to_atom
    |> carrier_module
  end
end
