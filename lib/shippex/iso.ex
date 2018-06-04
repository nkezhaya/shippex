defmodule Shippex.ISO do
  @moduledoc """
  This module contains data and functions for obtaining geographic data in
  compliance with the ISO-3166-2 standard.
  """

  @iso Poison.decode!(File.read!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json'))

  @doc """
  Converts a full state name to its state code, or abbreviation.

      iex> ISO.full_state_to_abbreviation("Texas")
      "TX"
      iex> ISO.full_state_to_abbreviation("teXaS")
      "TX"
      iex> ISO.full_state_to_abbreviation("TX")
      nil
      iex> ISO.full_state_to_abbreviation("AlberTa")
      "AB"
      iex> ISO.full_state_to_abbreviation("Veracruz")
      "VER"
      iex> ISO.full_state_to_abbreviation("Yucatán")
      "YUC"
      iex> ISO.full_state_to_abbreviation("Yucatan")
      "YUC"
      iex> ISO.full_state_to_abbreviation("YucatAN")
      "YUC"
      iex> ISO.full_state_to_abbreviation("Not a state.")
      nil
  """
  @spec full_state_to_abbreviation(String.t()) :: nil | String.t()
  def full_state_to_abbreviation(state) when is_bitstring(state) do
    state = filter_for_comparison(state)

    Enum.find_value(@iso, fn {country, %{"divisions" => divisions}} ->
      divisions
      |> Enum.find(fn {_state_code, full_state} ->
        filter_for_comparison(full_state) == state
      end)
      |> case do
        nil ->
          false

        {state_code, _full_state} ->
          String.replace_prefix(state_code, "#{country}-", "")
      end
    end)
  end

  @doc """
  Returns a map of country codes and their full names.

      iex> countries = ISO.countries()
      ...> match? %{"US" => "United States"}, countries
      true
  """
  @spec countries() :: %{String.t() => String.t()}
  def countries() do
    Enum.reduce(@iso, %{}, fn {code, %{"name" => name}}, acc ->
      Map.put(acc, code, name)
    end)
  end

  @doc """
  Returns a map of state codes and full names for the given 2-letter country
  code.

      iex> states = ISO.states("US")
      ...> match? %{"TX" => "Texas", "PR" => "Puerto Rico"}, states
      true
      iex> states = ISO.states("MX")
      ...> match? %{"AGU" => "Aguascalientes"}, states
      true
      iex> ISO.states("Not a country.")
      %{}
  """
  @spec states(String.t()) :: %{String.t() => String.t()}
  def states(country \\ "US") do
    states = @iso[country] || %{}

    case states["divisions"] do
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

      iex> ISO.abbreviation_to_country_name("US")
      "United States"
      iex> ISO.abbreviation_to_country_name("TN")
      "Tunisia"
      iex> ISO.abbreviation_to_country_name("TX")
      nil
  """
  @spec abbreviation_to_country_name(String.t()) :: nil | String.t()
  def abbreviation_to_country_name(abbr) when is_bitstring(abbr) do
    countries()[abbr]
  end

  defp filter_for_comparison(string) do
    string
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end
end
