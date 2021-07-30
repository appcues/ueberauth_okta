defmodule Ueberauth.Okta.Mixfile do
  use Mix.Project

  @version "0.2.1"
  @source_url "https://github.com/jjcarstens/ueberauth_okta"

  def project do
    [app: :ueberauth_okta,
     version: @version,
     name: "Ueberauth Okta",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     deps: deps(),
     docs: docs(),
     preferred_cli_env: [
       docs: :docs,
       "hex.build": :docs,
       "hex.publish": :docs
     ]
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
     {:jason, "~> 1.2"},
     {:oauth2, "~> 2.0"},
     {:ueberauth, "~> 0.7"},

     # dev/test only dependencies
     {:credo, "~> 1.5", only: [:dev, :test]},

     # docs dependencies
     {:ex_doc, "~> 0.24", only: :docs}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp description do
    "An Ueberauth strategy for using Okta to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jon Carstens"],
      licenses: ["MIT"],
      links: %{"GitHub": @source_url}]
  end
end
