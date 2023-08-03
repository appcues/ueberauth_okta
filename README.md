# Überauth Okta

[![Module Version](https://img.shields.io/hexpm/v/ueberauth_okta.svg)](https://hex.pm/packages/ueberauth_okta)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ueberauth_okta/)
[![Total Download](https://img.shields.io/hexpm/dt/ueberauth_okta.svg)](https://hex.pm/packages/ueberauth_okta)
[![License](https://img.shields.io/hexpm/l/ueberauth_okta.svg)](https://github.com/jjcarstens/ueberauth_okta/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/jjcarstens/ueberauth_okta.svg)](https://github.com/jjcarstens/ueberauth_okta/commits/master)

> Okta strategy for Überauth.

## Installation

Add `:ueberauth_okta` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ueberauth_okta, "~> 1.0"}]
end
```

## Setup

You'll need to register a new application with Okta and get the `client_id`
and `client_secret`. That setup is out of the scope of this library, but some
notes to remember are:

  * Ensure `Authorization Code` grant type is enabled
  * You have valid `Login Redirect Urls` listed for the app that correctly
    reference your callback route(s)
  * `user` or `group` permissions may need to be added to your Okta app
    before successfully authenticating

Include the provider in your configuration for Ueberauth with any
applicable configuration options (Okta and OAuth2 options are supported):

```elixir
config :ueberauth, Ueberauth,
  providers: [
    okta: {Ueberauth.Strategy.Okta, [client_id: "12345"]}
  ]
```

**Note**: Provider options are evaluated at compile time by default (see [Plug](https://hexdocs.pm/plug/1.14.0/Plug.html#module-plugs))
so if you use `runtime.exs` or another mechanism to load options into the
Application environment, you'll want to use the `Ueberauth.Strategy.Okta.OAuth`
scope. See below for details

### Okta Options

* `:oauth2_module` - OAuth module to use (default: `Ueberauth.Strategy.Okta.OAuth`)
* `:oauth2_params` - query parameters for the oauth request. See [Okta OAuth2
  documentation](https://developer.okta.com/docs/api/resources/oidc#authorize)
  for list of parameters. _Note that not all parameters are compatible with this flow_.
  (default: `[scope: "openid email profile"]`)
* `:uid_field` - default: `:sub`

### OAuth2 options

The default OAuth2 module for making the requests is `Ueberauth.Strategy.Okta.OAuth`
which uses the following options:

* `:site` - (**required**) Full request URL
* `:client_id` - (**required**) Okta client ID
* `:client_secret` - (**required**) Okta client secret
* `:authorize_url` - default:  "/oauth2/v1/authorize",
* `:token_url` - default:  "/oauth2/v1/token",
* `:userinfo_url` - default:  "/oauth2/v1/userinfo"
* `:authorization_server_id` - If supplied, URLs for the request will be adjusted to include
    the custom Okta Authorization Server ID
* Any `OAuth2.Client.t()` option

These options can be provided with the provider settings, or under the `Ueberauth.Strategy.Okta.OAuth` scope:

```elixir
config :ueberauth, Ueberauth.Strategy.Okta.OAuth,
  site: "https://your-doman.okta.com",
  client_id: System.get_env("OKTA_CLIENT_ID"),
  client_secret: System.get_env("OKTA_CLIENT_SECRET")
```

#### Multiple Providers (Multitenant)

To support multiple providers, scope the settings to the same provider key you
used when configuring `Ueberauth`:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    okta: {Ueberauth.Strategy.Okta, []}
  ]

config :ueberauth, Ueberauth.Strategy.Okta.OAuth,
  okta: [
    site: "https://your-doman.okta.com"
    client_id: System.get_env("OKTA_CLIENT_ID"),
    client_secret: System.get_env("OKTA_CLIENT_SECRET")
  ]
```

Scoped OAuth settings will take precedence over the global settings

### Adding Request Flow

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

## Copyright and License

Copyright (c) 2022 Jon Carstens

Released under the [MIT License](./LICENSE.md).
