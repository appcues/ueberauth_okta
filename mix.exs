defmodule Ueberauth.Okta.Mixfile do
  use Mix.Project

  @version "1.1.4"
  @source_url "https://github.com/appcues/ueberauth_okta"

  def project do
    [
      app: :ueberauth_okta,
      version: @version,
      name: "Ueberauth Okta",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.10"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      description: "An Ueberauth strategy for using Okta to authenticate your users.",
      files: ["CHANGELOG.md", "lib", "mix.exs", "README.md", "LICENSE.md"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ueberauth_okta/changelog.html",
        GitHub: @source_url
      }
    ]
  end
end
