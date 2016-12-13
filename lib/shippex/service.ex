defmodule Shippex.Service do
  @enforce_keys [:carrier, :code, :description]
  defstruct [:carrier, :code, :description]

  alias __MODULE__, as: S

  def services_for_carrier(carrier) when is_bitstring(carrier), do: services_for_carrier(String.to_atom(carrier))
  def services_for_carrier(carrier) when is_atom(carrier) do
    case carrier do
      :ups ->
        [
          %S{carrier: carrier, code: "01", description: "UPS Next Day Air"},
          %S{carrier: carrier, code: "02", description: "UPS 2nd Day Air"},
          %S{carrier: carrier, code: "12", description: "UPS 3 Day Select"},
          %S{carrier: carrier, code: "03", description: "UPS Ground"}
        ]

      _ ->
        raise "Invalid carrier: #{inspect carrier}"
    end
  end

  def all() do
    Enum.map(Shippex.carriers, &__MODULE__.services_for_carrier/1)
    |> Enum.reduce([], &++/2)
  end

  def by_carrier_and_code(carrier, code) do
    services_for_carrier(carrier)
    |> Enum.find(nil, fn(s) -> s.code == code end)
  end
end
