defmodule Shippex.Carrier.USPS.Client do
  @moduledoc false
  use HTTPoison.Base

  def process_url(endpoint) do
    subdomain =
      case Shippex.env() do
        :dev -> "stg-secure"
        :prod -> "secure"
      end

    "https://#{subdomain}.shippingapis.com/#{endpoint}"
  end

  def process_request_body(params) do
    params =
      Enum.map(params, fn
        {k, v} when is_atom(k) -> {k, v}
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
      end)

    {:form, params}
  end
end
