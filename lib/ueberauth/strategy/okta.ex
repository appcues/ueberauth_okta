defmodule Ueberauth.Strategy.Okta do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Okta.

  ## Setup

  You'll need to register a new application with Okta and get the `client_id`
  and `client_secret`. That setup is out of the scope of this library, but some
  notes to remember are:

    * Ensure `Authorization Code` grant type is enabled

    * You have valid `Login Redirect Urls` listed for the app that correctly
      reference your callback route(s)

    * `user` or `group` permissions may need to be added to your Okta app
      before successfully authenticating

  Include the provider in your configuration for Ueberauth:

      config :ueberauth, Ueberauth,
        providers: [
          okta: { Ueberauth.Strategy.Okta, [] }
        ]

  Then include the configuration for Okta:

      config :ueberauth, Ueberauth.Strategy.Okta.OAuth,
        client_id: System.get_env("OKTA_CLIENT_ID"),
        client_secret: System.get_env("OKTA_CLIENT_SECRET"),
        site: "https://your-doman.okta.com"

  If you haven't already, create a pipeline and setup routes for your callback
  handler:

      pipeline :auth do
        Ueberauth.plug "/auth"
      end
      scope "/auth" do
        pipe_through [:browser, :auth]
        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the
  `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller
        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end
        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you
  register your provider.

  To set the `uid_field`: (Default is `:sub`):

      config :ueberauth, Ueberauth,
        providers: [
          okta: { Ueberauth.Strategy.Okta, [uid_field: :email] }
        ]

  To set the params that will be sent in the OAuth request, use the
  `oauth2_params` key:

      config :ueberauth, Ueberauth,
        providers: [
          okta: {
            Ueberauth.Strategy.Okta,
            [oauth2_params: [scope: "openid email", max_age: 3600]]
          }
        ]

  See [Okta OAuth2
  documentation](https://developer.okta.com/docs/api/resources/oidc#authorize)
  for list of parameters.

  _Note that not all parameters are compatible with this flow_.
  """
  use Ueberauth.Strategy, uid_field: :sub,
                          oauth2_module: Ueberauth.Strategy.Okta.OAuth,
                          oauth2_params: [scope: "openid email profile"]

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  alias Plug.Conn

  @doc """
  Includes the credentials from the Okta response.
  """
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
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.okta_token,
        user: conn.private.okta_user
      }
    }
  end

  @doc """
  Handles the initial redirect to the okta authentication page.

  Supports `state` and `redirect_uri` params which are required for Okta /authorize request. These will also be generated if omitted.
  `redirect_uri` in Ueberauth.Strategy.Okta.OAuth config will take precedence over value provided here
  """
  def handle_request!(conn) do
    redirect_uri = conn.params["redirect_uri"] || callback_url(conn)
    opts = Keyword.merge(conn.private.ueberauth_request_options.options, redirect_uri: redirect_uri)

    params = conn
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
  def handle_callback!(%Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    opts = Keyword.merge(conn.private.ueberauth_request_options.options, redirect_uri: callback_url(conn))


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
  def handle_cleanup!(conn) do
    conn
    |> put_private(:okta_user, nil)
    |> put_private(:okta_token, nil)
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
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
    opts = conn.private.ueberauth_request_options.options

    with {:ok, %OAuth2.Response{status_code: status, body: body}} <- Ueberauth.Strategy.Okta.OAuth.get_user_info(token, _headers = [], opts),
         {200, user} <- {status, body}
    do
      put_private(conn, :okta_user, user)
    else
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, error("OAuth2", inspect(reason)))
      {401, _} ->
        set_errors!(conn, error("Okta token [401]", "unauthorized"))
      {status, body} when status in 400..599 ->
        set_errors!(conn, error("Okta [#{status}]", inspect(body)))
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key) || Keyword.get(default_options(), key)
  end
end
