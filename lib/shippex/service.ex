defmodule Shippex.Service do
  @enforce_keys [:carrier, :code, :description]
  defstruct [:carrier, :code, :description]

  alias __MODULE__, as: S

  def services_for_carrier(carrier) do
    case carrier do
      :ups ->
        [
          %S{carrier: carrier, code: "01", description: "UPS Next Day Air"},
          %S{carrier: carrier, code: "02", description: "UPS 2nd Day Air"},
          %S{carrier: carrier, code: "12", description: "UPS 3 Day Select"},
          %S{carrier: carrier, code: "03", description: "UPS Ground"}
        ]

      _ ->
        raise "Invalid carrier: #{carrier}"
    end
  end

  def by_carrier_and_code(carrier, code) do
    services_for_carrier(carrier)
    |> Enum.find(nil, fn(s) -> s.code == code end)
  end
end
