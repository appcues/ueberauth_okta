defmodule Ueberauth.Strategy.Okta do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Okta.

  ## Setup

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
  scope. See `Ueberauth.Strategy.Okta.OAuth` module doc for more details.

  ### Okta Options

  * `:oauth2_module` - OAuth module to use (default: `Ueberauth.Strategy.Okta.OAuth`)
  * `:oauth2_params` - query parameters for the oauth request. See [Okta OAuth2
  documentation](https://developer.okta.com/docs/api/resources/oidc#authorize)
  for list of parameters. _Note that not all parameters are compatible with this flow_.
  (default: `[scope: "openid email profile"]`)
  * `:uid_field` - default: `:sub`
  """
  use Ueberauth.Strategy,
    uid_field: :sub,
    oauth2_module: Ueberauth.Strategy.Okta.OAuth,
    oauth2_params: [scope: "openid email profile"],
    authorize_url: "/oauth2/v1/authorize",
    token_url: "/oauth2/v1/token",
    userinfo_url: "/oauth2/v1/userinfo"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  alias Plug.Conn

  @doc """
  Includes the credentials from the Okta response.
  """
  @impl Ueberauth.Strategy
  def credentials(conn) do
    token = conn.private.okta_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: token.other_params["scope"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Okta callback.
  """
  @impl Ueberauth.Strategy
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.okta_token,
        user: conn.private.okta_user
      }
    }
  end

  @doc """
  Handles the initial redirect to the okta authentication page.

  Supports `state` and `redirect_uri` params which are required for Okta
  /authorize request. These will also be generated if omitted.
  `redirect_uri` from the strategy config will take precedence over value
  provided here
  """
  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    opts =
      options(conn)
      |> Keyword.put(:redirect_uri, callback_url(conn))
      |> add_oauth_options(conn)

    params =
      conn
      |> option(:oauth2_params)
      |> with_state_param(conn)

    module = option(conn, :oauth2_module)
    url = apply(module, :authorize_url!, [params, opts])
    redirect!(conn, url)
  end

  @doc """
  Handles the callback from Okta.

  When there is a failure from Okta the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Okta is returned in the `Ueberauth.Auth` struct.
  """
  @impl Ueberauth.Strategy
  def handle_callback!(%Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)

    opts =
      options(conn)
      |> Keyword.put(:redirect_uri, callback_url(conn))
      |> add_oauth_options(conn)

    case apply(module, :get_token, [[code: code], opts]) do
      {:ok, %{token: token}} ->
        fetch_user(conn, token)

      {:error, %{body: %{"error" => key, "error_description" => message}, status_code: status}} ->
        set_errors!(conn, error("#{key} [#{status}]", message))

      err ->
        set_errors!(conn, error("Unknown Error fetching token", inspect(err)))
    end
  end

  @doc false
  def handle_callback!(%Conn{params: %{"error" => key, "error_description" => message}} = conn) do
    set_errors!(conn, error(key, message))
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Okta response around during the callback.
  """
  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
    |> put_private(:okta_user, nil)
    |> put_private(:okta_token, nil)
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  @impl Ueberauth.Strategy
  def info(conn) do
    user = conn.private.okta_user

    %Info{
      name: user["name"],
      first_name: user["given_name"],
      last_name: user["family_name"],
      nickname: user["nickname"],
      email: user["email"],
      location: user["address"],
      phone: user["phone_number"],
      urls: %{profile: user["profile"]}
    }
  end

  @doc """
  Fetches the uid field from the Okta response. This defaults to the option `uid_field` which in-turn defaults to `sub`
  """
  @impl Ueberauth.Strategy
  def uid(conn) do
    conn
    |> option(:uid_field)
    |> to_string()
    |> fetch_uid(conn)
  end

  defp fetch_uid(field, conn) do
    conn.private.okta_user[field]
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :okta_token, token)
    module = option(conn, :oauth2_module)

    opts =
      options(conn)
      |> Keyword.put(:token, token)
      |> add_oauth_options(conn)

    with {:ok, user} <- module.get_user_info(_headers = [], opts) do
      put_private(conn, :okta_user, user)
    else
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, error("OAuth2", inspect(reason)))

      {:error, %{status_code: 401}} ->
        set_errors!(conn, error("Okta token [401]", "unauthorized"))

      {:error, %{status_code: status, body: body}} when status in 400..599 ->
        set_errors!(conn, error("Okta [#{status}]", inspect(body)))
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key) || Keyword.get(default_options(), key)
  end

  defp add_oauth_options(opts, conn) do
    oauth_opts = Application.get_env(:ueberauth, Ueberauth.Strategy.Okta.OAuth, [])

    # The Ueberauth helper function says strategy_name, but this is the provider
    # name used from the Application config
    provider = strategy_name(conn)
    provider_str = to_string(provider)

    provider_opts =
      Enum.find_value(oauth_opts, oauth_opts, fn
        {^provider, v} -> v
        {^provider_str, v} -> v
        _ -> false
      end)

    Keyword.merge(opts, provider_opts)
  end
end
