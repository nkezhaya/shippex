if Code.ensure_loaded?(CSV) and Code.ensure_loaded?(Jason) do
  defmodule Mix.Tasks.BuildUsps do
    alias Shippex.ISO
    require Logger

    @moduledoc false

    # Builds a JSON file with the format:
    # %{ISO_CODE => %{"usps_code" => USPS_CODE,
    #                 "usps_name" => USPS_NAME}}
    def run(_) do
      all =
        File.stream!(csv("usps.csv"))
        |> CSV.decode!(strip_fields: true)
        |> Enum.to_list()
        |> Enum.uniq()

      all
      |> Enum.reject(fn [name, _code] -> province?(name, all) end)
      |> Enum.reject(fn [name, code] ->
        # Do not save it if it's identical to the ISO name
        uses_iso_name?(code, name)
      end)
      |> Enum.reduce(%{}, fn [usps_name, code], acc ->
        iso_code = ISO.country_code(usps_name)
        iso_name = ISO.country_name(iso_code)
        usps_code = code_for_usps_name(usps_name)

        cond do
          is_nil(iso_code) and is_nil(usps_code) ->
            if usps_name =~ "Tilos" do
              IO.inspect(parens_country(usps_name, all))
            end

            Logger.warn("Nothing found for #{usps_name}")
            acc

          usps_code == iso_code and usps_name != iso_name ->
            Map.put_new(acc, iso_code, %{"usps_name" => usps_name})

          true ->
            acc
        end
      end)
      |> overrides()
      |> Enum.reject(&is_nil/1)
      |> Map.new()
      |> Jason.encode!()
      |> Jason.Formatter.pretty_print()
      |> write()
    end

    def province?(usps_name, all_countries) do
      case parens_country(usps_name, all_countries) do
        nil -> false
        s -> not is_nil(ISO.country_code(s))
      end
    end

    def uses_iso_name?(code, usps_name) do
      ISO.country_code(usps_name) == code
    end

    # "Borneo (Indonesia)" => "Indonesia", but only if
    # "Indonesia" exists in the country list without anything
    # in parens.
    def parens_country(usps_name, all_countries) do
      usps_name
      |> String.replace(~r/(.*)\((.*)\)$/, "\\2")
      |> String.trim()
      |> case do
        "" ->
          nil

        "Taiwan" ->
          "Taiwan"

        ip ->
          Enum.find_value(all_countries, fn [name, _] ->
            if name == ip, do: ip
          end)
      end
    end

    def code_for_usps_name("British Virgin Islands"),
      do: ISO.country_code("Virgin Islands (British)")

    def code_for_usps_name("Saint Barthelemy (Guadeloupe)"),
      do: ISO.country_code("Saint Barthélemy")

    def code_for_usps_name("Congo, Republic of the"), do: ISO.country_code("Congo (the)")
    def code_for_usps_name("Georgia, Republic of"), do: ISO.country_code("Georgia")
    def code_for_usps_name("Burma"), do: ISO.country_code("Myanmar")
    def code_for_usps_name("Vietnam"), do: ISO.country_code("Viet Nam")
    def code_for_usps_name("Cape Verde"), do: ISO.country_code("Cabo Verde")
    def code_for_usps_name("Vatican City"), do: ISO.country_code("Holy See (the)")

    def code_for_usps_name("Czech Republic"), do: "CZ"
    def code_for_usps_name("Laos"), do: "LA"
    def code_for_usps_name("Eire" <> _), do: "IR"
    def code_for_usps_name("Korea"), do: "KP"
    def code_for_usps_name("Korea, Democratic" <> _), do: "KP"
    def code_for_usps_name("North Korea"), do: "KP"
    def code_for_usps_name("Korea, Republic" <> _), do: "KR"
    def code_for_usps_name("South Korea"), do: "KR"
    def code_for_usps_name("Taiwan"), do: "TW"
    def code_for_usps_name("Great Britain and Northern Ireland" <> _), do: "GB"
    def code_for_usps_name("United Kingdom" <> _), do: "GB"

    for name <- ["South Sudan", "Serbia", "Syria", "North Macedonia"] do
      @prefix name
      def code_for_usps_name(@prefix <> _), do: ISO.country_code(@prefix)
    end

    def code_for_usps_name(_), do: nil

    def overrides(usps) do
      usps
      |> Map.put("KR", %{"usps_name" => "North Korea"})
      |> Map.put("SH", %{"usps_name" => "Saint Helena"})
      |> Map.put("MM", %{"usps_name" => "Burma"})
    end

    def write(json) do
      File.write!(:code.priv_dir(:shippex) ++ '/usps-countries.json', json)
    end

    defp csv(path) do
      :code.priv_dir(:shippex) ++ '/csv/#{path}'
    end
  end
end
