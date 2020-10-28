defmodule Mix.Tasks.BuildUsps do
  import Shippex.Util, only: [unaccent: 1]
  require Logger

  @moduledoc false

  @iso_countries Shippex.ISO.countries()

  def run(_) do
    read()
    |> Floki.parse_fragment!()
    |> Floki.traverse_and_update(0, fn
      {"a", _, [_, {"b", [{"class", "caret"}], []}]}, acc -> {nil, acc}
      el, acc -> {el, acc}
    end)
    |> elem(0)
    |> Floki.find("a[href]")
    |> Enum.map(fn {_, _, [c]} -> c end)
    |> Enum.map(fn name ->
      if k = key_for_name(name) do
        k
      else
        Logger.warn("Nothing found for #{name}")
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> write()
  end

  def key_for_name(name) do
    cond do
      k = code_for_name(name) -> {k, name}
      k = starting_code_for_name(name) -> {k, name}
      k = code_for_usps_name(name) -> {k, name}
      k = code_for_short_name(name) -> {k, name}
      true -> nil
    end
  end

  # %{"SL" => "Sierra Leone"}
  def code_for_name(country_name) do
    Enum.find_value(@iso_countries, fn {code, name} ->
      cond do
        name == country_name -> code
        unaccent(name) == country_name -> code
        parens_to_comma_delimited(name, false) == country_name -> code
        parens_to_comma_delimited(name, true) == country_name -> code
        true -> nil
      end
    end)
  end

  def starting_code_for_name(country_name) do
    # Does the ISO name ("United States of America") contain the name as a
    # prefix?

    Enum.find_value(@iso_countries, fn {code, name} ->
      if String.starts_with?(unaccent(name), country_name), do: code
    end)
  end

  def code_for_short_name(country_name) do
    # Does the ISO name ("United States of America") contain the name as a
    # prefix?
    country_name = String.upcase(country_name)

    Enum.find_value(@iso_countries, fn {code, _name} ->
      short_name = Shippex.ISO.data()[code]["short_name"]
      if country_name == short_name, do: code
    end)
  end

  def code_for_usps_name("British Virgin Islands"), do: code_for_name("Virgin Islands (British)")
  def code_for_usps_name("Congo, Republic of the"), do: code_for_name("Congo (the)")
  def code_for_usps_name("Czech Republic"), do: code_for_name("Czechia")
  def code_for_usps_name("Georgia, Republic of"), do: code_for_name("Georgia")
  def code_for_usps_name("Laos"), do: code_for_name("Lao People's Democratic Republic (the)")
  def code_for_usps_name("Burma"), do: code_for_name("Myanmar")
  def code_for_usps_name("Vietnam"), do: code_for_name("Viet Nam")
  def code_for_usps_name("South Sudan" <> _), do: code_for_name("South Sudan")
  def code_for_usps_name("Serbia" <> _), do: code_for_name("Serbia")
  def code_for_usps_name("Syria" <> _), do: code_for_name("Syria")
  def code_for_usps_name("North Macedonia" <> _), do: code_for_name("North Macedonia")
  def code_for_usps_name(_), do: nil

  # "Korea (Republic of)" -> "Korea, Republic of"
  def parens_to_comma_delimited(name, false),
    do: String.replace(name, ~r/(\w+)\s+\(the (.*)\)/, "\\1, \\2")

  def parens_to_comma_delimited(name, true),
    do: String.replace(name, ~r/(\w+)\s+\((.*)\)/, "\\1, \\2")

  def read() do
    File.read!(:code.priv_dir(:shippex) ++ '/usps-countries.html')
  end

  def write(json) do
    File.write!(:code.priv_dir(:shippex) ++ '/usps-countries.json', json)
  end
end
