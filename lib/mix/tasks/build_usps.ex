defmodule Mix.Tasks.BuildUsps do
  @moduledoc false

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
        {k, name}
      else
        IO.inspect("Nothing found for #{name}")
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> write()
  end

  # %{"SL" => "Sierra Leone"}
  @iso_countries Shippex.ISO.countries()
  def key_for_name(country_name) do
    Enum.find_value(@iso_countries, fn {code, name} ->
      if name == country_name, do: code
    end)
  end

  def read() do
    File.read!(:code.priv_dir(:shippex) ++ '/usps-countries.html')
  end

  def write(json) do
    File.write!(:code.priv_dir(:shippex) ++ '/usps-countries.json', json)
  end
end
