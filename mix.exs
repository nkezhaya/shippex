defmodule Shippex.Mixfile do
  use Mix.Project

  @source_url "https://github.com/whitepaperclip/shippex"

  def project do
    [
      app: :shippex,
      version: "0.13.0",
      elixir: "~> 1.9",
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
    Shippex is an abstraction of commonly used features in shipping with various
    carriers. It provides a (hopefully) pleasant API to work with carrier-
    provided web interfaces for fetching rates and printing shipping labels.
    """
  end

  defp package do
    [
      name: :shippex,
      files: [
        "lib/shippex.ex",
        "lib/shippex",
        "priv/iso-3166-2.json",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Nick Kezhaya"],
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
      {:iso, "~> 1.0"},
      {:csv, "~> 2.4", optional: true, only: [:dev]}
    ]
  end

  defp docs do
    [
      main: "Shippex",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
