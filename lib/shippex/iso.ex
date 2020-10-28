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
  Returns a map of country codes and their full names.

      iex> countries = ISO.countries()
      ...> match? %{"US" => "United States of America (the)"}, countries
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
