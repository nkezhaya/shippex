defmodule Shippex.Service do
  @moduledoc """
  A `Service` represents a carrier's offered shipping option. This is not
  initialized by the user directly. However, some convenience functions exist
  to display all offered carrier services to the user.

  Service fields are:

    * `:id`          - A unique Shippex ID that can be used to perform lookups or fetch rates
    * `:carrier`     - The atom representing the carrier
    * `:code`        - Internally used by Shippex for API requests
    * `:description` - A user-friendly string containing the name of the service

  ## Example

        iex> Shippex.Service.services_for_carrier(:ups)
        [
          %Shippex.Service{id: :ups_next_day_air, carrier: :ups, description: "UPS Next Day Air"},
          %Shippex.Service{id: :ups_second_day_air, carrier: :ups, description: "UPS 2nd Day Air"},
          %Shippex.Service{id: :ups_three_day_select, carrier: :ups, description: "UPS 3 Day Select"},
          %Shippex.Service{id: :ups_ground, carrier: :ups, description: "UPS Ground"}
        ]
  """

  alias __MODULE__, as: S
  alias Shippex.{Carrier, Shipment}

  @enforce_keys [:id, :carrier, :description]
  defstruct [:id, :carrier, :description]

  @type t() :: %__MODULE__{
          id: atom(),
          carrier: Carrier.t(),
          description: String.t()
        }

  @doc """
  Looks up a shipping service by its unique Shippex ID. Returns nil if none
  exist.

      iex> Service.get(:usps_priority)
      %Service{id: :usps_priority, carrier: :usps, description: "Priority Mail"}
      iex> Service.get(:invalid_service)
      nil
  """
  @compile {:inline, get: 1}
  @spec get(atom) :: t | nil
  def get(:ups_ground), do: %S{id: :ups_ground, carrier: :ups, description: "UPS Ground"}

  def get(:ups_next_day_air),
    do: %S{id: :ups_next_day_air, carrier: :ups, description: "UPS Next Day Air"}

  def get(:ups_second_day_air),
    do: %S{id: :ups_second_day_air, carrier: :ups, description: "UPS 2nd Day Air"}

  def get(:ups_three_day_select),
    do: %S{id: :ups_three_day_select, carrier: :ups, description: "UPS 3 Day Select"}

  def get(:ups_expedited), do: %S{id: :ups_expedited, carrier: :ups, description: "UPS Expedited"}

  def get(:ups_express_saver),
    do: %S{id: :ups_express_saver, carrier: :ups, description: "UPS Express Saver"}

  def get(:ups_express), do: %S{id: :ups_express, carrier: :ups, description: "UPS Express"}
  def get(:ups_standard), do: %S{id: :ups_standard, carrier: :ups, description: "UPS Standard"}

  def get(:ups_worldwide_saver),
    do: %S{id: :ups_worldwide_saver, carrier: :ups, description: "UPS Worldwide Saver"}

  def get(:ups_worldwide_expedited),
    do: %S{id: :ups_worldwide_expedited, carrier: :ups, description: "UPS Worldwide Expedited"}

  def get(:ups_worldwide_express),
    do: %S{id: :ups_worldwide_express, carrier: :ups, description: "UPS Worldwide Express"}

  def get(:usps_media), do: %S{id: :usps_media, carrier: :usps, description: "Media Mail Parcel"}

  def get(:usps_library),
    do: %S{id: :usps_library, carrier: :usps, description: "Library Mail Parcel"}

  def get(:usps_first_class),
    do: %S{id: :usps_first_class, carrier: :usps, description: "First-Class Mail Parcel"}

  def get(:usps_retail_ground),
    do: %S{id: :usps_retail_ground, carrier: :usps, description: "USPS Retail Ground"}

  def get(:usps_parcel_select),
    do: %S{id: :usps_parcel_select, carrier: :usps, description: "Parcel Select Ground"}

  def get(:usps_priority),
    do: %S{id: :usps_priority, carrier: :usps, description: "Priority Mail"}

  def get(:usps_priority_express),
    do: %S{id: :usps_priority_express, carrier: :usps, description: "Priority Mail Express"}

  def get(:usps_priority_international),
    do: %S{
      id: :usps_priority_international,
      carrier: :usps,
      description: "Priority Mail International"
    }

  def get(:usps_gxg), do: %S{id: :usps_gxg, carrier: :usps, description: "GXG"}
  def get(_service), do: nil

  @doc """
  Returns all services for `carrier` based on the `shipment` provided.

      Shippex.Service.services_for_carrier(:ups)
  """
  @spec services_for_carrier(Carrier.t(), Shipment.t()) :: [t]
  def services_for_carrier(carrier, %Shipment{to: %{country: dst}}) do
    carrier
    |> services_for_carrier_to_country(dst)
    |> Enum.map(&get/1)
    |> Enum.reject(&is_nil/1)
  end

  defp services_for_carrier_to_country(:usps, "US") do
    ~w(usps_media usps_library usps_first_class usps_retail_ground usps_parcel_select usps_priority usps_priority_express)a
  end

  defp services_for_carrier_to_country(:usps, _country) do
    ~w(usps_first_class usps_priority usps_priority_express usps_gxg)a
  end

  defp services_for_carrier_to_country(:ups, "US") do
    ~w(ups_ground ups_three_day_select ups_second_day_air ups_next_day_air)a
  end

  defp services_for_carrier_to_country(:ups, _country) do
    ~w(ups_standard ups_worldwide_expedited ups_worldwide_express ups_worldwide_saver)a
  end

  # Returns the service code used by the third-party API. Only used internally
  # for API requests.

  @doc false
  @compile {:inline, service_code: 1}
  @spec service_code(atom | t) :: String.t() | nil
  def service_code(%S{id: id}), do: service_code(id)
  def service_code(:ups_ground), do: "03"
  def service_code(:ups_next_day_air), do: "01"
  def service_code(:ups_second_day_air), do: "02"
  def service_code(:ups_three_day_select), do: "12"
  def service_code(:ups_expedited), do: "02"
  def service_code(:ups_express_saver), do: "13"
  def service_code(:ups_express), do: "01"
  def service_code(:ups_standard), do: "11"
  def service_code(:ups_worldwide_saver), do: "65"
  def service_code(:ups_worldwide_expedited), do: "08"
  def service_code(:ups_worldwide_express), do: "07"
  def service_code(:usps_media), do: "MEDIA MAIL"
  def service_code(:usps_library), do: "LIBRARY MAIL"
  def service_code(:usps_first_class), do: "FIRST CLASS"
  def service_code(:usps_retail_ground), do: "RETAIL GROUND"
  def service_code(:usps_parcel_select), do: "PARCEL SELECT GROUND"
  def service_code(:usps_priority), do: "PRIORITY"
  def service_code(:usps_priority_express), do: "PRIORITY EXPRESS"
  def service_code(:usps_priority_international), do: "PRIORITY INTERNATIONAL"
  def service_code(:usps_gxg), do: "GXG"
end
