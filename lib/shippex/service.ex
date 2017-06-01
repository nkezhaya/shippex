defmodule Shippex.Service do
  @moduledoc """
  A `Service` represents a carrier's offered shipping speeds. This is not
  initialized by the user directly. However, some convenience functions exist
  to display all offered carrier services to the user.

      iex> Shippex.Service.services_for_carrier(:ups)
      [
        %Shippex.Service{carrier: carrier, code: "01", description: "UPS Next Day Air"},
        %Shippex.Service{carrier: carrier, code: "02", description: "UPS 2nd Day Air"},
        %Shippex.Service{carrier: carrier, code: "12", description: "UPS 3 Day Select"},
        %Shippex.Service{carrier: carrier, code: "03", description: "UPS Ground"}
      ]
  """

  @enforce_keys [:carrier, :code, :description]
  defstruct [:carrier, :code, :description]

  alias __MODULE__, as: S

  @doc """
  Returns all services for `carrier`.

      Shippex.Service.services_for_carrier(:ups)
  """
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
  def services_for_carrier(carrier) when is_bitstring(carrier) do
    carrier
    |> String.downcase
    |> String.to_atom
    |> services_for_carrier
  end

  @doc """
  Returns all services from all supported carriers.
  """
  def all() do
    Enum.map(Shippex.carriers, &__MODULE__.services_for_carrier/1)
    |> Enum.reduce([], &++/2)
  end

  @doc """
  Returns a service from a carrier by its code, if it exists. Otherwise, returns
  `nil`.

      iex> Shippex.Service.by_carrier_and_code(:ups, "01")
      %Shippex.Service{carrier: carrier, code: "01", description: "UPS Next Day Air"},
      iex> Shippex.Service.by_carrier_and_code(:ups, "999999999")
      nil
  """
  def by_carrier_and_code(carrier, code) do
    services_for_carrier(carrier)
    |> Enum.find(nil, fn(s) -> s.code == code end)
  end
end
