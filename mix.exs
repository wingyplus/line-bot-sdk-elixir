defmodule LINE.Bot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :line_bot_sdk,
      version: "0.3.0",
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "LINE Messaging API SDK for Elixir.",
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:plug, "~> 1.16"},
      {:plug_crypto, "~> 2.0"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false, warn_if_outdated: true},
      {:passby, "~> 0.2", only: :test, runtime: false}
    ]
  end

  defp docs do
    [
      groups_for_modules: [
        "Messaging API": ~r/^LINE\.Bot\.MessagingApi(Blob)?(\.|$)/,
        Webhook: ~r/^LINE\.Bot\.(Webhook(\.|$)|Dummy$)/,
        "Channel Access Token": ~r/^LINE\.Bot\.ChannelAccessToken(\.|$)/,
        Insight: ~r/^LINE\.Bot\.Insight(\.|$)/,
        LIFF: ~r/^LINE\.Bot\.Liff(\.|$)/,
        "Manage Audience": ~r/^LINE\.Bot\.ManageAudience(Blob)?(\.|$)/,
        "Module Attach": ~r/^LINE\.Bot\.(LineModuleAttach$|ModuleAttach\.)/,
        Module: ~r/^LINE\.Bot\.(LineModule$|Module\.)/,
        Shop: ~r/^LINE\.Bot\.Shop(\.|$)/
      ]
    ]
  end

  defp package do
    [
      name: "line_bot_sdk",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/wingyplus/line-bot-sdk-elixir"
      },
      files: ~w(.formatter.exs lib mix.exs README* LICENSE*)
    ]
  end
end
