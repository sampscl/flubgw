defmodule FlubGw.Mixfile do
  use Mix.Project

  def project do
    [app: :flub_gw,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :gproc, :ghoul, :flub],
     mod: {FlubGw.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ghoul, "~> 0.1"},
      {:gproc, "~> 0.5"},
      {:shorter_maps, "~> 2.2"},
      {:flub, "~> 1.1"},
      {:httpotion, "~> 3.0"},
      #{:pattern_tap, "~> 0.4"},
    ]
  end
end
