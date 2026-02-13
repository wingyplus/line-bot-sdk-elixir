defmodule LINE.Bot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :line_bot_sdk,
      version: "1.0.0",
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: """
      This document describes LINE Mission Stickers API.
      """,
      deps: deps()
    ]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:ex_doc, "~> 0.40", only: :docs, runtime: false, warn_if_outdated: true},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp package do
    [
      name: "line_bot_sdk",
      files: ~w(.formatter.exs config lib mix.exs README* LICENSE*)
    ]
  end
end
