defmodule ExShip.Mixfile do
  use Mix.Project
  @version "0.18.1"
  @source_url "https://github.com/data-twister/exship"

  def project do
    [
      app: :exship,
      version: @version,
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:eex, :logger]]
  end

  defp description do
    """
    ExShip is a fork of the excellent shippex module by Nick Kezhaya which is an abstraction of commonly used features in shipping with various
    carriers. It provides a (hopefully) pleasant API to work with carrier-
    provided web interfaces for fetching rates and printing shipping labels.
    """
  end

  defp package do
    [
      name: :exship,
      files: [
        "lib/exship.ex",
        "lib/exship",
        "priv/iso-3166-2.json",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:httpoison, ">= 0.0.0"},
      {:sweet_xml, ">= 0.0.0"},
      {:html_entities, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:decimal, "~> 1.3"},
      {:iso, "~> 1.2"},
      {:csv, "~> 2.4", optional: true, only: [:dev]},
      {:nanoid, "~> 2.0"}
    ]
  end

  defp docs do
    [
      main: "ExShip",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
