defmodule Shippex.ISO do
  @moduledoc """
  This module contains data and functions for obtaining geographic data in
  compliance with the ISO-3166-2 standard.
  """

  import Shippex.Util, only: [unaccent: 1]

  @iso Shippex.Config.json_library().decode!(
         File.read!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json')
       )

  @type country_code() :: binary()

  @doc """
  Returns all ISO-3166-2 data.
  """
  @spec data() :: %{country_code() => map()}
  def data(), do: @iso

  @doc """
  Returns a map of country codes and their full names. Takes in a list of
  optional atoms to tailor the results. For example, `:with_subdivisions` only
  includes countries with subdivisions.

      iex> countries = ISO.countries()
      iex> get_in(countries, ["US", "name"])
      "United States of America (the)"
      iex> get_in(countries, ["PR", "name"])
      "Puerto Rico"

      iex> countries = ISO.countries([:with_subdivisions])
      iex> countries["PR"]
      nil

      iex> countries = ISO.countries([:exclude_territories])
      iex> countries["PR"]
      nil
  """
  @spec countries([atom()]) :: %{String.t() => map()}
  def countries(opts \\ []) do
    with_subdivisions? = :with_subdivisions in opts
    exclude_territories? = :exclude_territories in opts

    Enum.reduce(@iso, %{}, fn {code, %{"subdivisions" => subs} = country}, acc ->
      cond do
        with_subdivisions? and subs == %{} -> acc
        exclude_territories? and territory?(code) -> acc
        true -> Map.put(acc, code, country)
      end
    end)
  end

  @doc """
  Returns true if the country with the given code is a territory of another
  country. This only applies to subdivisions that have their own country code.

      iex> ISO.territory?("PR")
      true

      iex> ISO.territory?("US")
      false

      iex> ISO.territory?("TX")
      false
  """
  @spec territory?(country_code()) :: boolean()
  def territory?(code) do
    country = @iso[code]

    Enum.any?(@iso, fn
      {a_code, %{"subdivisions" => subdivisions}} ->
        case Map.get(subdivisions, "#{a_code}-#{code}") do
          %{"name" => name} ->
            equal_names?(name, country["name"]) or
              equal_names?(name, country["full_name"]) or
              equal_names?(name, country["short_name"])

          _ ->
            false
        end

      _ ->
        false
    end)
  end

  @doc """
  Converts a country's 2-letter code to its full name.

      iex> ISO.country_name("US")
      "United States of America (the)"

      iex> ISO.country_name("US", :informal)
      "United States of America"

      iex> ISO.country_name("US", :short_name)
      "UNITED STATES OF AMERICA"

      iex> ISO.country_name("TN")
      "Tunisia"

      iex> ISO.country_name("TX")
      nil
  """
  @spec country_name(country_code(), nil | :informal | :short_name) :: nil | String.t()
  def country_name(code, type \\ nil) do
    case @iso[code] do
      %{"name" => name, "short_name" => short_name} ->
        case type do
          nil -> name
          :short_name -> short_name
          :informal -> strip_parens(name)
        end

      _ ->
        nil
    end
  end

  @doc """
  Converts a full country name to its 2-letter ISO-3166-2 code.

      iex> ISO.country_code("United States")
      "US"

      iex> ISO.country_code("UNITED STATES")
      "US"

      iex> ISO.country_code("Mexico")
      "MX"

      iex> ISO.country_code("Venezuela")
      "VE"

      iex> ISO.country_code("Iran")
      "IR"

      iex> ISO.country_code("Taiwan")
      "TW"

      iex> ISO.country_code("Bolivia")
      "BO"

      iex> ISO.country_code("Not a country.")
      nil
  """
  @spec country_code(String.t()) :: nil | country_code()

  def country_code(country) do
    country
    |> String.upcase()
    |> do_country_code()
  end

  defp do_country_code("ASCENSION" <> _), do: "SH"
  defp do_country_code("BRITISH VIRGIN ISLANDS"), do: "VG"
  defp do_country_code("GREAT BRITAIN" <> _), do: "GB"
  defp do_country_code("IRAN" <> _), do: "IR"
  defp do_country_code("SAINT HELENA" <> _), do: "SH"
  defp do_country_code("SAINT MARTIN" <> _), do: "MF"
  defp do_country_code("SINT MAARTEN" <> _), do: "SX"
  defp do_country_code("SWAZILAND" <> _), do: "SZ"
  defp do_country_code("SYRIA" <> _), do: "SY"
  defp do_country_code("TAIWAN" <> _), do: "TW"
  defp do_country_code("TRISTAN" <> _), do: "SH"
  defp do_country_code("UNITED STATES" <> _), do: "US"
  defp do_country_code("UNITED KINGDOM" <> _), do: "GB"
  defp do_country_code("VENEZUELA" <> _), do: "VE"

  defp do_country_code(country) do
    Enum.find_value(@iso, fn
      {code, %{"short_name" => ^country}} ->
        code

      {code, %{"short_name" => short_name, "name" => name, "full_name" => full_name}} ->
        cond do
          String.upcase(name) == country -> code
          String.upcase(full_name) == country -> code
          strip_parens(short_name) == country -> code
          true -> nil
        end

      _ ->
        nil
    end)
  end

  defp strip_parens(short_name) do
    short_name
    |> String.replace(~r/\(([\w\s]+)\)$/i, "", global: true)
    |> unaccent()
    |> String.trim()
  end

  @doc """
  Converts a full subdivision name to its 2-letter ISO-3166-2 code. The country
  MUST be an ISO-compliant 2-letter country code.

      iex> ISO.subdivision_code("US", "Texas")
      "US-TX"

      iex> ISO.subdivision_code("US", "US-TX")
      "US-TX"

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

      iex> ISO.subdivision_code("CA", "US-TX")
      nil

      iex> ISO.subdivision_code("MX", "Not a subdivision.")
      nil
  """
  @spec subdivision_code(country_code(), String.t()) :: nil | String.t()
  def subdivision_code(country, subdivision)
      when is_binary(subdivision) and is_binary(country) do
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

          equal_names?(full_subdivision, subdivision) or
            (is_binary(variation) and equal_names?(variation, subdivision))
        end)
        |> case do
          nil -> nil
          {subdivision_code, _full_subdivision} -> subdivision_code
        end
    end
  end

  defp equal_names?(a, b) do
    filter_for_comparison(a) == filter_for_comparison(b)
  end

  defp filter_for_comparison(string) do
    string
    |> String.trim()
    |> String.upcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end

  @doc """
  Finds the country data for the given country. May be an ISO-3166-compliant
  country code or a string to perform a search with. Return a tuple in the
  format `{code, data}` if a country was found; otherwise `nil`.

      iex> {code, data} = ISO.find_country("United States")
      iex> code
      "US"
      iex> data |> Map.get("short_name")
      "UNITED STATES OF AMERICA"

      iex> {code, data} = ISO.find_country("US")
      iex> code
      "US"
      iex> data |> Map.get("short_name")
      "UNITED STATES OF AMERICA"

      iex> ISO.find_country("Invalid")
      nil
  """

  @spec find_country(country_code() | String.t()) :: nil | {country_code(), map()}
  def find_country(country) do
    if code?(country) do
      country
    else
      country_code(country)
    end
    |> case do
      nil -> nil
      code -> {code, @iso[code]}
    end
  end

  defp code?(<<code::binary-size(2)>>), do: not is_nil(@iso[code])
  defp code?(_), do: false

  @doc """
  Takes a country input and subdivision and returns the validated,
  ISO-3166-compliant subdivision code in a tuple.

      iex> ISO.find_subdivision_code("US", "TX")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision_code("US", "US-TX")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision_code("US", "Texas")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision_code("United States", "Texas")
      {:ok, "US-TX"}

      iex> ISO.find_subdivision_code("SomeCountry", "SG-SG")
      {:error, "Invalid country: SomeCountry"}

      iex> ISO.find_subdivision_code("SG", "SG-Invalid")
      {:error, "Invalid subdivision 'SG-Invalid' for country: SG (SG)"}
  """
  @spec find_subdivision_code(country_code(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def find_subdivision_code(country, subdivision) do
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

  @doc """
  Returns the subdivision data for the ISO-3166-compliant subdivision code.

      iex> ISO.get_subdivision("US-TX")
      {:ok, %{"category" => "state", "name" => "Texas"}}

      iex> ISO.get_subdivision("MX-CMX")
      {:ok, %{"category" => "federal district", "name" => "Ciudad de México"}}

      iex> ISO.get_subdivision("11-SG")
      {:error, :not_found}

      iex> ISO.get_subdivision("SG-Invalid")
      {:error, :not_found}

      iex> ISO.get_subdivision("Invalid")
      {:error, :not_found}
  """
  @spec get_subdivision(String.t()) :: {:ok, map()} | {:error, :invalid_country | :not_found}
  def get_subdivision(subdivision_code) do
    with <<country_code::binary-size(2), "-", _::binary>> <- subdivision_code,
         %{} = sub <- get_in(@iso, [country_code, "subdivisions", subdivision_code]) do
      {:ok, sub}
    else
      _ -> {:error, :not_found}
    end
  end
end
