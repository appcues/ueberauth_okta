# Überauth Okta

[![Module Version](https://img.shields.io/hexpm/v/ueberauth_okta.svg)](https://hex.pm/packages/ueberauth_okta)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ueberauth_okta/)
[![Total Download](https://img.shields.io/hexpm/dt/ueberauth_okta.svg)](https://hex.pm/packages/ueberauth_okta)
[![License](https://img.shields.io/hexpm/l/ueberauth_okta.svg)](https://github.com/jjcarstens/ueberauth_okta/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/jjcarstens/ueberauth_okta.svg)](https://github.com/jjcarstens/ueberauth_okta/commits/master)

> Okta strategy for Überauth.

## Call for maintainers!

If you have any interest in taking over or maintaining this library, please
reach out to me. I wrote this for use at a previous company, but am no longer
there nor do I use Okta anymore. I try to keep this updated as best I can,
but it is not actively maintained and help would be much appreciated :heart:

## Installation

Add `:ueberauth_okta` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ueberauth_okta, "~> 0.2"}]
end
```

Add the strategy to your applications:

```elixir
def application do
  [extra_applications: [:ueberauth_okta]]
end
```

You'll need to register a new application with Okta and get the `client_id` and `client_secret`. That setup is out of the scope of this library, but some notes to remember are:
  * Ensure `Authorization Code` grant type is enabled
  * You have valid `Login Redirect Urls` listed for the app that correctly reference your callback route(s)
  * `user` and/or `group` permissions may need to be added to your Okta app before successfully authenticating

Include these settings in your provider configuration for Ueberauth:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    okta: { Ueberauth.Strategy.Okta, [
      client_id: System.get_env("OKTA_CLIENT_ID"),
      client_secret: System.get_env("OKTA_CLIENT_SECRET"),
      site: "https://your-doman.okta.com"
    ] }
  ]
```

If you have configured a custom Okta Authorization Server, you can specify it using the
`authorization_server_id` key. This will cause request URLs to be adjusted to include the ID,
saving you the effort of configuring the `authorization_url`, `token_url` etc... directly.

You can also include options for the underlying OAuth strategy. If using the
default (`Ueberauth.Strategy.Okta.OAuth`), then options for `OAuth2.Client.t()`
are supported.

If you haven't already, create a pipeline and setup routes for your callback handler
```elixir
pipeline :auth do
  plug Ueberauth
end
scope "/auth" do
  pipe_through [:browser, :auth]
  get "/:provider/callback", AuthController, :callback
end
```

Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct
```elixir
defmodule MyApp.AuthController do
  use MyApp.Web, :controller
  def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
    # do things with the failure
  end
  def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
    # do things with the auth
  end
end
```

## Goals
This is just the start `ueberauth_okta` strategy for support with Okta auth protocols. Initially, I will mainly be focused on Okta OAuth, but once that is up I will move onto other autentication routes I'd also like to support (see below):

- [x] OAuth 2.0
- [ ] SAML

## Copyright and License

Copyright (c) 2018 Jon Carstens

Released under the [MIT License](./LICENSE.md).
