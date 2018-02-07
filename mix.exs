defmodule Shippex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :shippex,
      version: "0.6.1",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    []
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
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Nick Kezhaya"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/whitepaperclip/shippex"}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :doc},
      {:httpoison, ">= 0.0.0"},
      {:poison, ">= 0.0.0"},
      {:sweet_xml, ">= 0.0.0"},
      {:html_entities, ">= 0.0.0"},
      {:decimal, "~> 1.3"}
    ]
  end
end
