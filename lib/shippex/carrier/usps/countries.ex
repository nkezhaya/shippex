defmodule Shippex.USPS.Countries do
  @countries Jason.decode!(File.read!(:code.priv_dir(:shippex) ++ '/usps-countries.json'))

  @doc """
  Returns the USPS country name for the given country code. This is necessary
  because USPS does not follow the ISO-3166 standard.

      iex> USPS.Countries.country_name("US")
      "United States"
  """
  @spec country_name(String.t()) :: String.t() | nil

  # US not found in the international country list
  def country_name("US"), do: "United States"

  def country_name(code) do
    Map.get(@countries, code)
  end
end
