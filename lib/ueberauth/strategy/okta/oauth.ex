defmodule Ueberauth.Strategy.Okta.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Okta.

  Required values are `site`, `client_id`, `client_secret` and should be
  included in your configuration:

      config :ueberauth, Ueberauth.Strategy.Okta.OAuth,
        site: "https://your-doman.okta.com"
        client_id: System.get_env("OKTA_CLIENT_ID"),
        client_secret: System.get_env("OKTA_CLIENT_SECRET")

  You can also include options from the `OAuth2.Client` struct which will take
  precedence.
  """
  require Jason
  use OAuth2.Strategy

  alias OAuth2.{Client, Strategy.AuthCode}

  @defaults [
    strategy: __MODULE__,
    authorize_url: "/oauth2/v1/authorize",
    token_url: "/oauth2/v1/token",
    userinfo_url: "/oauth2/v1/userinfo"
  ]

  @doc """
  Construct a client for requests to Okta.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Okta.OAuth.client(
        redirect_uri: "http://localhost:4000/auth/okta/callback"
      )

  This will be setup automatically for you in `Ueberauth.Strategy.Okta`.

  These options are only useful for usage outside the normal callback phase of
  Ueberauth.
  """
  def client(opts \\ []) do
    config = Keyword.take(opts, [:client_id, :client_secret, :site])
    config = if config != [], do: config, else: Application.fetch_env!(:ueberauth, __MODULE__)

    config = config
             |> validate_config_option!(:client_id)
             |> validate_config_option!(:client_secret)
             |> validate_config_option!(:site)

    client_opts = @defaults
                  |> Keyword.merge(opts)
                  |> Keyword.merge(config)

    Client.new(client_opts)
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  """
  def authorize_url!(params \\ [], client_opts \\ []) do
    client_opts
    |> client()
    |> Client.authorize_url!(params)
  end

  def get_user_info(token, headers \\ [], opts \\ []) do
    opts = Keyword.merge(opts, token: token)

    opts
    |> client()
    |> Client.get(userinfo_url(), headers, opts)
  end

  def get_token(params \\ [], options \\ []), do: Client.get_token(client(options), params)

  # Strategy Callbacks

  def authorize_url(client, params) do
    client
    |> put_param(:nonce, Base.encode16(:crypto.strong_rand_bytes(32)))
    |> AuthCode.authorize_url(params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> validate_code(params)
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:redirect_uri, client.redirect_uri)
    |> basic_auth()
    |> put_headers(headers)
  end

  defp userinfo_url() do
    Application.get_env(:ueberauth, __MODULE__)
    |> Keyword.get(:userinfo_url, Keyword.get(@defaults, :userinfo_url))
  end

  defp validate_code(client, params) do
    code = Keyword.get(params, :code, client.params["code"])
    unless code do
      raise OAuth2.Error, reason: "Missing required key `code` for `#{inspect(__MODULE__)}`"
    end
    put_param(client, :code,  code)
  end

  defp validate_config_option!(config, key) when is_list(config) do
    with val when is_bitstring(val) <- Keyword.get(config, key),
         {^key, true} <- if(key == :site, do: {key, String.starts_with?(val, "http")}, else: {key, val != ""})
    do
      config
    else
      false -> raise "#{inspect(key)} in config :ueberauth, Ueberauth.Strategy.Okta.OAuth must be a bitstring"
      {:site, false} -> raise ":site in config :ueberauth, Ueberauth.Strategy.Okta.OAuth is not a url"
      {key, false} -> raise "#{inspect(key)} in config :ueberauth, Ueberauth.Strategy.Okta.OAuth is an empty string"
    end
  end
  defp validate_config_option!(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Okta.OAuth is not a keyword list, as expected"
  end
end
