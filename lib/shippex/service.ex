defmodule Shippex.Service do
  @moduledoc """
  A `Service` represents a carrier's offered shipping speeds. This is not
  initialized by the user directly. However, some convenience functions exist
  to display all offered carrier services to the user.

      iex> Shippex.Service.services_for_carrier(:ups)
      [
        %Shippex.Service{carrier: :ups, code: "01", description: "UPS Next Day Air"},
        %Shippex.Service{carrier: :ups, code: "02", description: "UPS 2nd Day Air"},
        %Shippex.Service{carrier: :ups, code: "12", description: "UPS 3 Day Select"},
        %Shippex.Service{carrier: :ups, code: "03", description: "UPS Ground"}
      ]
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:carrier, :code, :description]
  defstruct [:carrier, :code, :description]

  alias __MODULE__, as: S

  @doc """
  Returns all services for `carrier`.

      Shippex.Service.services_for_carrier(:ups)
  """
  def services_for_carrier(carrier, ori_country \\ "US", dst_country \\ "US")
  def services_for_carrier(:ups, "US", "US") do
    [%S{carrier: :ups, code: "01", description: "UPS Next Day Air"},
     %S{carrier: :ups, code: "02", description: "UPS 2nd Day Air"},
     %S{carrier: :ups, code: "12", description: "UPS 3 Day Select"},
     %S{carrier: :ups, code: "03", description: "UPS Ground"}]
  end
  def services_for_carrier(:ups, "US", _oc),
    do: intl_services() ++ [%S{carrier: :ups, code: "65", description: "UPS Worldwide Saver"}]
  def services_for_carrier(:ups, "CA", "CA") do
    [%S{carrier: :ups, code: "11", description: "UPS Standard"},
     %S{carrier: :ups, code: "02", description: "UPS Expedited"},
     %S{carrier: :ups, code: "13", description: "UPS Express Saver"},
     %S{carrier: :ups, code: "01", description: "UPS Express"}]
  end
  def services_for_carrier(:ups, "CA", _dc),
    do: intl_services()
  def services_for_carrier(:ups, "MX", "MX"),
    do: intl_services()
  def services_for_carrier(:ups, "MX", _dc),
    do: intl_services()
  def services_for_carrier(:ups, oc, dc),
    do: raise "Invalid/unsupported country: #{inspect oc} or #{inspect dc}"
  def services_for_carrier(carrier, oc, dc) when is_bitstring(carrier) do
    carrier
    |> String.downcase
    |> String.to_atom
    |> services_for_carrier(oc, dc)
  end
  def services_for_carrier(carrier, _oc, _dc) do
    raise "Invalid carrier: #{inspect carrier}"
  end
  defp intl_services do
    [%S{carrier: :ups, code: "11", description: "UPS Standard"},
     %S{carrier: :ups, code: "08", description: "UPS Worldwide Expedited"},
     %S{carrier: :ups, code: "07", description: "UPS Worldwide Express"}]
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
      %Shippex.Service{carrier: :ups, code: "01", description: "UPS Next Day Air"},
      iex> Shippex.Service.by_carrier_and_code(:ups, "999999999")
      nil
  """
  def by_carrier_and_code(carrier, code) do
    services_for_carrier(carrier)
    |> Enum.find(nil, & &1.code == code)
  end
end
