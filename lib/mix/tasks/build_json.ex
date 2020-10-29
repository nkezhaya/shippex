if Code.ensure_loaded?(CSV) and Code.ensure_loaded?(Jason) do
  defmodule Mix.Tasks.BuildJson do
    # Compiles the CSVs into a usable JSON file.
    @moduledoc false

    use Mix.Task

    def run(_) do
      all_subdivision_categories =
        File.stream!(csv("subdivision-categories.csv"))
        |> CSV.decode!(strip_fields: true)
        |> Enum.to_list()
        |> Enum.reduce(%{}, fn
          [country_code, _, _, category_code, _, "eng", category_name, _], acc ->
            Map.update(acc, country_code, %{category_code => category_name}, fn cats ->
              Map.put(cats, category_code, category_name)
            end)

          _, acc ->
            acc
        end)

      all_subdivisions =
        File.stream!(csv("subdivision-names.csv"))
        |> CSV.decode!(strip_fields: true)
        |> Enum.to_list()

      File.stream!(csv("country-codes.csv"))
      |> CSV.decode!(strip_fields: true)
      |> Enum.reduce(%{}, fn
        [code_2, _, _, _, "officially-assigned", name, short_name_caps, full_name], acc ->
          Map.put_new(acc, code_2, %{
            "name" => name,
            "full_name" => full_name,
            "short_name" => short_name_caps,
            "subdivisions" =>
              list_subdivisions(all_subdivisions, code_2, all_subdivision_categories[code_2])
          })

        _row, acc ->
          acc
      end)
      |> Jason.encode!()
      |> Jason.Formatter.pretty_print()
      |> write_json()
    end

    defp list_subdivisions(all_subdivisions, country_code, categories) do
      Enum.reduce(all_subdivisions, %{}, fn
        [^country_code, _, _, category_code, division_code, _, _, name, variation | _], acc ->
          variation =
            case remove_notes(variation) do
              "" -> nil
              v -> v
            end

          division = %{"name" => remove_notes(name), "category" => categories[category_code]}

          division =
            case variation do
              nil -> division
              v -> Map.put(division, "variation", v)
            end

          Map.put_new(acc, division_code, division)

        _, acc ->
          acc
      end)
    end

    defp remove_notes(name) do
      if String.contains?(name, "(see also") do
        name
        |> String.replace(~r/(.*)(\s*)\(see also.*\)$/, "\\1")
        |> String.trim()
      else
        name
      end
    end

    defp write_json(json) do
      File.write!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json', json)
    end

    defp csv(path) do
      :code.priv_dir(:shippex) ++ '/csv/#{path}'
    end
  end
end
