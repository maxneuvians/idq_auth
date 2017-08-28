defmodule IdqAuth.Explicit do
  @moduledoc """
  This module exposes the explicit authorization flow. The primary function of the
  module `authenticate/1` takes an existing plug connection, `conn`, and depending on the existing
  `conn.params` proceeds with different steps of the OAuth2 authentication process.

  If no params exist in `conn` then the assumption is that the user needs to proceed to the
  explicit idQ® login page to authenticate with their device application. If the `params` map includes
  the unique `state` and `code` keys, then the `state` is checked and the `code` used to request
  an authentication token. The authentication token is then exchanged for user data and the data is added
  to the `conn` as part of the `assigns` map. The assumption is the application will then take assigned
  data and act appropriately.
  """

  import Plug.{Conn, HTML}

  alias IdqAuth.Api

  @doc """
  Accepts a `conn` and uses the content of `conn.params` to determin a course of action. If `params` is
  empty the function will modify the `conn` to redirect to the idQ® explicit authentication login page.

  If the `params` map includes the unique `state` and `code` keys, then the `state` is checked
  and the `code` used to request an authentication token. The authentication token is then exchanged
  for user data and the data is added to the `conn` as part of the `assigns` map.

  Should at any point an error occur, the status code will be set to `400` and an error message attached.
  """
  @spec authenticate(%Plug.Conn{}) :: %Plug.Conn{}
  def authenticate(conn) do
    case parse_params(conn, conn.params) do
      {:redirect, path, token} ->
        body = "<html><body>You are being <a href=\"#{html_escape(path)}\">redirected</a>.</body></html>"
        conn
        |> put_session(:idq_auth_token, token)
        |> put_resp_header("location", path)
        |> send_resp(302, body)
        |> halt
      {:user, user} ->
        conn
        |> assign(:idq_user, user)
        |> delete_session(:idq_auth_token)
      _ ->
        conn
        |> delete_session(:idq_auth_token)
        |> put_resp_content_type("text/plain")
        |> send_resp(400, "An idQ explicit auth error occured")
        |> halt
    end
  end

  @spec parse_params(%Plug.Conn{}, %{"state": String.t, "code": String.t}) :: {:user, map()}
  defp parse_params(conn, %{"state" => one_time_token, "code" => code}) do
    with  true <- get_session(conn, :idq_auth_token) == one_time_token,
          %{"access_token" => token} <- Api.token(code),
          user <- Api.user(token)
    do
      {:user, user}
    else
      false -> {:error, "One time code does not match"}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec parse_params(%Plug.Conn{}, map()) :: {:redirect, String.t}
  defp parse_params(_conn, _params) do
    one_time_token = UUID.uuid4
    {:redirect, Api.auth(one_time_token), one_time_token}
  end
end
