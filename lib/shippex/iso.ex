defmodule Shippex.ISO do
  @moduledoc """
  This module contains data and functions for obtaining geographic data in
  compliance with the ISO-3166-2 standard.
  """

  @iso Shippex.json_library().decode!(File.read!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json'))

  @doc """
  Returns all ISO-3166-2 data.
  """
  def data() do
    @iso
  end

  @doc """
  Returns a map of country codes and their full names. Takes in a list of optional atoms to tailor the results. For example, `:with_subdivisions` only includes countries with subdivisions.

      iex> countries = ISO.countries()
      ...> countries["US"]
      "United States of America (the)"
      ...> countries["PR"]
      "Puerto Rico"
      iex> countries = ISO.countries([:with_subdivisions])
      ...> countries["PR"]
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
  Returns a map of state codes and full names for the given 2-letter country
  code.

      iex> states = ISO.states("US")
      ...> get_in(states, ["TX", "name"])
      "Texas"
      ...> get_in(states, ["PR", "name"])
      "Puerto Rico"
      iex> states = ISO.states("MX")
      ...> get_in(states, ["AGU", "name"])
      "Aguascalientes"
      iex> ISO.states("Not a country.")
      %{}
  """
  @spec states(String.t()) :: %{String.t() => String.t()}
  def states(country \\ "US") do
    states = @iso[country] || %{}

    case states["subdivisions"] do
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
end
