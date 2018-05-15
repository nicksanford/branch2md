defmodule Gitlog.MixProject do
  use Mix.Project

  def project do
    [
      app: :gitlog,
      escript: escript_config(),
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [ plt_add_deps: :transitive,
                  plt_add_apps: [:inets],
                  flags: ["-Wunmatched_returns",
                          :error_handling,
                          :race_conditions,
                          :underspecs] ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Gitlog.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:dialyxir, "~> 0.5.0", only: [:dev], runtime: false}
    ]
  end

  defp escript_config do
    [
      main_module: Gitlog.CLI
    ]
  end
end
