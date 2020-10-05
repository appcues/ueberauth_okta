defmodule Ueberauth.Okta.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :ueberauth_okta,
     version: @version,
     name: "Ueberauth Okta",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/jjcarstens/ueberauth_okta",
     homepage_url: "https://github.com/jjcarstens/ueberauth_okta",
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
     {:oauth2, "~> 2.0"},
     {:ueberauth, "~> 0.6"},

     # dev/test only dependencies
     {:credo, "~> 0.8", only: [:dev, :test]},

     # docs dependencies
     {:earmark, ">= 0.0.0", only: :dev},
     {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Okta to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jon Carstens"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/jjcarstens/ueberauth_okta"}]
  end
end
