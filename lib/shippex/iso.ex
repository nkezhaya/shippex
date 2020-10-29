defmodule Shippex.ISO do
  @moduledoc """
  This module contains data and functions for obtaining geographic data in
  compliance with the ISO-3166-2 standard.
  """

  @iso Shippex.Config.json_library().decode!(
         File.read!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json')
       )

  @doc """
  Returns all ISO-3166-2 data.
  """
  def data(), do: @iso

  @doc """
  Returns a map of country codes and their full names. Takes in a list of
  optional atoms to tailor the results. For example, `:with_subdivisions` only
  includes countries with subdivisions.

      iex> countries = ISO.countries()
      iex> countries["US"]
      "United States of America (the)"

      iex> countries["PR"]
      "Puerto Rico"

      iex> countries = ISO.countries([:with_subdivisions])
      iex> countries["PR"]
      nil
  """
  @spec countries([atom()]) :: %{String.t() => String.t()}
  def countries(opts \\ []) do
    with_subdivisions? = :with_subdivisions in opts

    Enum.reduce(@iso, %{}, fn {code, %{"name" => name} = country}, acc ->
      cond do
        with_subdivisions? and country["subdivisions"] == %{} -> acc
        true -> Map.put(acc, code, name)
      end
    end)
  end

  @doc """
  Returns a map of subdivision codes and full names for the given 2-letter
  country code.

      iex> get_in(ISO.subdivisions("US"), ["TX", "name"])
      "Texas"

      iex> get_in(ISO.subdivisions("US"), ["PR", "name"])
      "Puerto Rico"

      iex> get_in(ISO.subdivisions("MX"), ["AGU", "name"])
      "Aguascalientes"

      iex> ISO.subdivisions("Not a country.")
      %{}
  """
  @spec subdivisions(String.t()) :: %{String.t() => String.t()}
  def subdivisions(country \\ "US") do
    subdivisions = @iso[country] || %{}

    case subdivisions["subdivisions"] do
      nil ->
        %{}

      divisions ->
        divisions
        |> Enum.map(fn {code, name} ->
          code = String.replace_prefix(code, "#{country}-", "")
          {code, name}
        end)
        |> Map.new()
    end
  end

  @doc """
  Converts a country's 2-letter code to its full name.

      iex> ISO.country_code_to_name("US")
      "United States of America (the)"

      iex> ISO.country_code_to_name("TN")
      "Tunisia"

      iex> ISO.country_code_to_name("TX")
      nil
  """
  @spec country_code_to_name(String.t()) :: nil | String.t()
  def country_code_to_name(abbr) when is_bitstring(abbr) do
    countries()[abbr]
  end

  @doc """
  Converts a full country name to its 2-letter ISO-3166-2 code.

      iex> Address.country_code("United States")
      "US"
      iex> Address.country_code("Mexico")
      "MX"
      iex> Address.country_code("Not a country.")
      nil
  """
  @spec country_code(String.t()) :: nil | String.t()
  def country_code("UNITED STATES" <> _), do: "US"

  def country_code(country) do
    country = String.upcase(country)

    Enum.find_value(@iso, fn
      {code, %{"short_name" => ^country}} ->
        code

      {code, %{"name" => name, "full_name" => full_name}} ->
        if String.upcase(name) == country or String.upcase(full_name) == country do
          code
        end

      _ ->
        nil
    end)
  end

  @doc """
  Converts a full state name to its 2-letter ISO-3166-2 code. The country MUST
  be an ISO-compliant 2-letter country code.

      iex> Address.subdivision_code("Texas")
      "US-TX"

      iex> Address.subdivision_code("teXaS")
      "US-TX"

      iex> Address.subdivision_code("TX")
      "US-TX"

      iex> Address.subdivision_code("US-TX")
      "US-TX"

      iex> Address.subdivision_code("AlberTa", "CA")
      "CA-AB"

      iex> Address.subdivision_code("Veracruz", "MX")
      "MX-VER"

      iex> Address.subdivision_code("Yucatán", "MX")
      "MX-YUC"

      iex> Address.subdivision_code("Yucatan", "MX")
      "MX-YUC"

      iex> Address.subdivision_code("YucatAN", "MX")
      "MX-YUC"

      iex> Address.subdivision_code("Not a state.")
      nil
  """
  @spec subdivision_code(String.t(), String.t()) :: nil | String.t()
  def subdivision_code(country, state)
      when is_bitstring(state) and is_bitstring(country) do
    divisions = @iso[country]["subdivisions"]

    cond do
      Map.has_key?(divisions, "#{country}-#{state}") ->
        "#{country}-#{state}"

      Map.has_key?(divisions, state) ->
        state

      true ->
        state = filter_for_comparison(state)

        divisions
        |> Enum.find(fn {_subdivision_code, %{"name" => full_state} = s} ->
          variation = s["variation"]

          filter_for_comparison(full_state) == state or
            (is_binary(variation) and filter_for_comparison(variation) == state)
        end)
        |> case do
          nil -> nil
          {subdivision_code, _full_state} -> subdivision_code
        end
    end
  end

  defp filter_for_comparison(string) do
    string
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end
end
