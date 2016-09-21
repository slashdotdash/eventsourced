defmodule EventSourced.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eventsourced,
      version: "0.1.0",
      elixir: "~> 1.3",
      description: description,
      package: package,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.13.2", only: :dev},
      {:mix_test_watch, "~> 0.2", only: :dev}
    ]
  end

  defp description do
"""
Build functional, event-sourced domain models.
"""
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Ben Smith"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/slashdotdash/eventsourced",
               "Docs" => "https://hexdocs.pm/eventsourced/"}
    ]
  end
end
