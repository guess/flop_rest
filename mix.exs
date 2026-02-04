defmodule FlopRest.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/guess/flop_rest"

  def project do
    [
      app: :flop_rest,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "FlopRest",
      description: "Parse Stripe-style REST API query params into Flop format for filtering, sorting, and pagination",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      preferred_cli_env: [coveralls: :test, "coveralls.html": :test],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:flop, "~> 0.26"},
      {:plug, "~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:styler, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}"
    ]
  end
end
