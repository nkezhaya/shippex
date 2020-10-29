defmodule Shippex.ISO do
  @moduledoc """
  This module contains data and functions for obtaining geographic data in
  compliance with the ISO-3166-2 standard.
  """

  @iso Shippex.Config.json_library().decode!(
         File.read!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json')
       )

  @default_country "US"

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
  def country_code_to_name(code) when is_bitstring(code) do
    countries()[code]
  end

  @doc """
  Converts a full country name to its 2-letter ISO-3166-2 code.

      iex> ISO.country_code("United States")
      "US"
      iex> ISO.country_code("Mexico")
      "MX"
      iex> ISO.country_code("Not a country.")
      nil
  """
  @spec country_code(String.t()) :: nil | String.t()

  def country_code(country) do
    country
    |> String.upcase()
    |> do_country_code()
  end

  defp do_country_code("UNITED STATES" <> _), do: "US"

  defp do_country_code(country) do
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
  Converts a full subdivision name to its 2-letter ISO-3166-2 code. The country
  MUST be an ISO-compliant 2-letter country code.

      iex> ISO.subdivision_code("Texas")
      "US-TX"

      iex> ISO.subdivision_code("teXaS")
      "US-TX"

      iex> ISO.subdivision_code("TX")
      "US-TX"

      iex> ISO.subdivision_code("US-TX")
      "US-TX"

      iex> ISO.subdivision_code("CA", "US-TX")
      nil

      iex> ISO.subdivision_code("CA", "AlberTa")
      "CA-AB"

      iex> ISO.subdivision_code("MX", "Veracruz")
      "MX-VER"

      iex> ISO.subdivision_code("MX", "Yucatán")
      "MX-YUC"

      iex> ISO.subdivision_code("MX", "Yucatan")
      "MX-YUC"

      iex> ISO.subdivision_code("MX", "YucatAN")
      "MX-YUC"

      iex> ISO.subdivision_code("Not a subdivision.")
      nil
  """
  @spec subdivision_code(String.t(), String.t()) :: nil | String.t()
  def subdivision_code(country \\ @default_country, subdivision)
      when is_bitstring(subdivision) and is_bitstring(country) do
    divisions = @iso[country]["subdivisions"]

    cond do
      Map.has_key?(divisions, "#{country}-#{subdivision}") ->
        "#{country}-#{subdivision}"

      Map.has_key?(divisions, subdivision) ->
        subdivision

      true ->
        subdivision = filter_for_comparison(subdivision)

        divisions
        |> Enum.find(fn {_subdivision_code, %{"name" => full_subdivision} = s} ->
          variation = s["variation"]

          filter_for_comparison(full_subdivision) == subdivision or
            (is_binary(variation) and filter_for_comparison(variation) == subdivision)
        end)
        |> case do
          nil -> nil
          {subdivision_code, _full_subdivision} -> subdivision_code
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

  @doc """
  Takes a subdivision and country input and returns the validated,
  ISO-3166-compliant results in a tuple.

      iex> ISO.find_subdivision("TX")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision("US", "TX")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision("US", "US-TX")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision("US", "Texas")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision("United States", "Texas")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision("SomeCountry", "SG-SG")
      {:error, "Invalid country: SomeCountry"}

      iex> ISO.find_subdivision("SG", "SG-Invalid")
      {:error, "Invalid subdivision 'SG-Invalid' for country: SG (SG)"}
  """
  @spec find_subdivision(any, any) ::
          {:ok, String.t(), String.t()} | {:error, String.t()}
  def find_subdivision(country \\ @default_country, subdivision) do
    country_code =
      case @iso do
        %{^country => %{}} -> country
        _ -> country_code(country)
      end

    cond do
      is_nil(country_code) ->
        {:error, "Invalid country: #{country}"}

      code = subdivision_code(country_code, subdivision) ->
        {:ok, code}

      true ->
        {:error, "Invalid subdivision '#{subdivision}' for country: #{country} (#{country_code})"}
    end
  end
end
