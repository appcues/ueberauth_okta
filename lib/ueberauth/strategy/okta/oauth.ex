defmodule Ueberauth.Strategy.Okta.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Okta.

  Required values are `site`, `client_id`, `client_secret` and should be
  included in your provider configuration:

      config :ueberauth, Ueberauth,
        providers: [
          okta: {Ueberauth.Strategy.Okta, [
            site: "https://your-doman.okta.com"
            client_id: System.get_env("OKTA_CLIENT_ID"),
            client_secret: System.get_env("OKTA_CLIENT_SECRET")
          ]}
        ]

  You can also include options from the `OAuth2.Client.t()` struct which will take
  precedence.
  """
  use OAuth2.Strategy

  alias OAuth2.{Client, Strategy.AuthCode}

  @after_compile __MODULE__
  def __after_compile__(env, _bytecode) do
    case Application.get_env(:ueberauth, Ueberauth.Strategy.Okta.OAuth, []) do
      [] ->
        env

      opts ->
        sample = [providers: [okta: {Ueberauth.Strategy.Okta, opts}]]

        raise """
        Cannot use `Ueberauth.Strategy.Okta.OAuth` in Application env

        Using `config :ueberauth, Ueberauth.Strategy.Okta.OAuth` is deprecated.

        Instead, put your options for Ueberauth.Strategy.Okta.OAuth in your provider
        settings for `Ueberauth.Strategy.Okta`:

        config :ueberauth, Ueberauth, #{inspect(sample, pretty: true)}
        """
    end
  end

  @doc """
  Construct a client for requests to Okta.

  Intended for use from Ueberauth.Strategy.Okta but supplying options for usage
  outside the normal callback phase of Ueberauth. See OAuth2.Client.t() for
  available options.
  """
  def client(opts \\ []) do
    opts
    |> configure_url(:authorize, "/authorize")
    |> configure_url(:token, "/token")
    |> validate_config_option!(:client_id)
    |> validate_config_option!(:client_secret)
    |> validate_config_option!(:site)
    |> Client.new()
    |> Client.put_serializer("application/json", Jason)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  """
  def authorize_url!(params \\ [], client_opts \\ []) do
    client_opts
    |> client()
    |> Client.authorize_url!(params)
  end

  def get_user_info(headers \\ [], opts \\ []) do
    userinfo_url =
      opts
      |> configure_url(:userinfo, "/userinfo")
      |> Keyword.fetch!(:userinfo_url)

    client(opts)
    |> Client.get(userinfo_url, headers, opts)
    |> case do
      {:ok, %{status_code: 200, body: user}} -> {:ok, user}
      {:ok, result} -> {:error, result}
      err -> err
    end
  end

  def get_token(params \\ [], options \\ []), do: Client.get_token(client(options), params)

  # Strategy Callbacks

  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    client
    |> put_param(:nonce, Base.encode16(:crypto.strong_rand_bytes(32)))
    |> AuthCode.authorize_url(params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> validate_code(params)
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:redirect_uri, client.redirect_uri)
    |> basic_auth()
    |> put_headers(headers)
  end

  defp validate_code(client, params) do
    code = Keyword.get(params, :code, client.params["code"])

    unless code do
      raise OAuth2.Error, reason: "Missing required key `code` for `#{inspect(__MODULE__)}`"
    end

    put_param(client, :code, code)
  end

  defp validate_config_option!(config, key) when is_list(config) do
    case Keyword.take(config, [key]) do
      [] ->
        raise "[Ueberauth.Strategy.Okta.OAuth] missing required key: #{inspect(key)} "

      [{_, ""}] ->
        raise "[Ueberauth.Strategy.Okta.OAuth] #{inspect(key)} is an empty string"

      [{:site, "http" <> _}] ->
        config

      [{:site, val}] ->
        raise "[Ueberauth.Strategy.Okta.OAuth] invalid :site - #{inspect(val)}"

      [{_, val}] when is_binary(val) ->
        config

      _ ->
        raise "[Ueberauth.Strategy.Okta.OAuth] #{inspect(key)} must be a string"
    end
  end

  defp validate_config_option!(_, _) do
    raise "[Ueberauth.Strategy.Okta.OAuth] strategy options must be a keyword list"
  end

  # Constructs default values for e.g. authorize_url based on the authorization_server_id, if it's
  # provided. Falls back to the global default for Okta. If the relevant config option is
  # already in opts (e.g. authorize_url), the existing option is always preferred.
  defp configure_url(opts, prefix, path) do
    Keyword.put_new_lazy(opts, :"#{prefix}_url", fn ->
      case opts[:authorization_server_id] do
        nil ->
          "/oauth2/v1#{path}"

        authorization_server_id when is_binary(authorization_server_id) ->
          "/oauth2/#{authorization_server_id}/v1#{path}"
      end
    end)
  end
end
