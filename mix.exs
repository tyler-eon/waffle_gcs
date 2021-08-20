defmodule Waffle.Storage.Google.CloudStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :waffle_gcs,
      name: "Waffle GCS",
      description: description(),
      version: "0.1.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      source_url: "https://github.com/kolorahl/waffle_gcs",
      homepage_url: "https://github.com/kolorahl/waffle_gcs"
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Google Cloud Storage integration for Waffle file uploader library."
  end

  defp package do
    [
      files: ~w(config/config.exs lib LICENSE mix.exs README.md),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/kolorahl/waffle_gcs"}
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:waffle, "~> 1.1"},
      {:goth, "~> 1.1"},
      {:google_api_storage, "~> 0.14"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
