if Code.ensure_loaded?(Floki) do
  defmodule Mix.Tasks.BuildUsps do
    import Shippex.Util, only: [unaccent: 1]
    require Logger

    @moduledoc false

    @iso_countries Shippex.ISO.countries()

    def run(_) do
      read()
      |> String.replace("’", "'")
      |> Floki.parse_fragment!()
      |> Floki.traverse_and_update(0, fn
        {"span", _, _}, acc -> {nil, acc}
        {"br", _, _}, acc -> {nil, acc}
        el, acc -> {el, acc}
      end)
      |> elem(0)
      |> Floki.find("a[name]")
      |> Enum.map(fn
        {_, _, [c]} -> c
        {_, _, [a, b]} -> "#{a} #{b}"
      end)
      |> Enum.map(&replace_name/1)
      |> Enum.map(fn s ->
        s = s |> String.replace(~r/\s+/, " ") |> String.trim()
        regex = ~r/([\w\s,']+)\s*\(([\w\s,']+)\)$/

        cond do
          String.contains?(s, ", United States") -> "United States"
          s =~ regex -> String.replace(s, regex, "\\2")
          true -> s
        end
      end)
      |> Enum.uniq()
      |> Enum.map(fn name ->
        # Do not save it if it's identical to the ISO name
        if uses_iso_name?(name), do: nil, else: name
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn name ->
        case key_for_name(name) do
          nil ->
            Logger.warn("Nothing found for #{name}")
            nil

          r ->
            r
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
        k = starting_code_for_name(name) -> {k, name}
        k = code_for_short_name(name) -> {k, name}
        k = code_for_usps_name(name) -> {k, name}
        true -> nil
      end
    end

    # %{"SL" => "Sierra Leone"}
    def uses_iso_name?(usps_name) do
      country =
        Enum.find(@iso_countries, fn {_code, iso_name} ->
          if iso_name == usps_name, do: true
        end)

      not is_nil(country)
    end

    def starting_code_for_name(country_name) do
      # Does the ISO name ("United States of America") contain the name as a
      # prefix?

      Enum.find_value(@iso_countries, fn {code, name} ->
        if String.starts_with?(unaccent(name), country_name), do: code
      end)
    end

    def code_for_short_name(country_name) do
      country_name = String.upcase(country_name)

      Enum.find_value(@iso_countries, fn {code, _name} ->
        short_name = Shippex.ISO.data()[code]["short_name"]
        if country_name == short_name, do: code
      end)
    end

    def code_for_usps_name("British Virgin Islands"),
      do: code_for_name("Virgin Islands (British)")

    def code_for_usps_name("Saint Barthelemy (Guadeloupe)"), do: code_for_name("Saint Barthélemy")
    def code_for_usps_name("Congo, Republic of the"), do: code_for_name("Congo (the)")
    def code_for_usps_name("Czech Republic"), do: code_for_name("Czechia")
    def code_for_usps_name("Georgia, Republic of"), do: code_for_name("Georgia")
    def code_for_usps_name("Laos"), do: code_for_name("Lao People's Democratic Republic (the)")
    def code_for_usps_name("Burma"), do: code_for_name("Myanmar")
    def code_for_usps_name("Vietnam"), do: code_for_name("Viet Nam")
    def code_for_usps_name("Cape Verde"), do: code_for_name("Cabo Verde")
    def code_for_usps_name("South Korea"), do: code_for_name("Korea (the Republic of)")
    def code_for_usps_name("Vatican City"), do: code_for_name("Holy See (the)")

    def code_for_usps_name("North Korea"),
      do: code_for_name("Korea (the Democratic People's Republic of)")

    for name <- ["South Sudan", "Serbia", "Syria", "North Macedonia"] do
      @prefix name
      def code_for_usps_name(@prefix <> _), do: code_for_name(@prefix)
    end

    def code_for_usps_name(_), do: nil

    def code_for_name(usps_name) do
      Enum.find_value(@iso_countries, fn {code, iso_name} ->
        if iso_name == usps_name, do: code
      end)
    end

    # Finally, this is the list of exceptions where even the USPS API does not
    # follow its own standard. The above is retained in case USPS fixes itself.

    for name <- ["Saint Martin", "Sint Maarten"] do
      @prefix name
      def replace_name(@prefix <> _), do: @prefix
    end

    def replace_name("Bosnia" <> _), do: "Bosnia-Herzegovina"
    def replace_name("Ascension"), do: "Saint Helena"
    def replace_name("Tristan da Cunha"), do: "Saint Helena"
    def replace_name(name), do: name

    def read() do
      File.read!(:code.priv_dir(:shippex) ++ '/usps-countries.html')
    end

    def write(json) do
      File.write!(:code.priv_dir(:shippex) ++ '/usps-countries.json', json)
    end
  end
end
