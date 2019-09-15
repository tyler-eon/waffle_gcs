defmodule Waffle.Storage.Google.CloudStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :waffle_gcs,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:waffle, "~> 0.0.3"},
      {:goth, "~> 1.1"},
      {:google_api_storage, "~> 0.12"},
    ]
  end
end
