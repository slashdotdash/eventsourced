defmodule EventSourced.Mixfile do
  use Mix.Project

  def project do
    [app: :eventsourced,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:uuid, "~> 1.1"}
    ]
  end
end
