defmodule Mix.Tasks.BuildJson do
  # Compiles the CSVs into a usable JSON file.
  @moduledoc false

  use Mix.Task

  def run(_) do
    all_subdivisions =
      File.stream!(csv("subdivision-names.csv"))
      |> CSV.decode!(strip_fields: true)
      |> Enum.to_list()

    File.stream!(csv("country-codes.csv"))
    |> CSV.decode!(strip_fields: true)
    |> Enum.reduce(%{}, fn
      [code_2, _, _, _, "officially-assigned", name | _], acc ->
        Map.put_new(acc, code_2, %{
          "name" => name,
          "divisions" => list_subdivisions(all_subdivisions, code_2)
        })

      _row, acc ->
        acc
    end)
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> write_json()
  end

  defp list_subdivisions(all_subdivisions, country_code) do
    Enum.reduce(all_subdivisions, %{}, fn
      [^country_code, _, _, _, division_code, _, _, name | _], acc ->
        Map.put_new(acc, division_code, name)

      _, acc ->
        acc
    end)
  end

  defp write_json(json) do
    File.write!(:code.priv_dir(:shippex) ++ '/iso-3166-2.json', json)
  end

  defp csv(path) do
    :code.priv_dir(:shippex) ++ '/csv/#{path}'
  end
end