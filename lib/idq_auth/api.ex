defmodule IdqAuth.Api do
  @moduledoc """
  A module that handles all the API calls to the
  idQ® servers as well as URL generators to redirect to
  idQ® servers.
  """

  @doc """
  Returns a new session identifier from the location headers
  resulting from an auth request. Primarily used to start implicit
  authentication.
  """
  @spec auth() :: %{"session": String.t} | {:error, String.t}
  def auth do
    query = Map.merge(%{response_type: "code"}, default_params())
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "auth?" <> URI.encode_query(query)) do
      %{status_code: 307, headers: headers} ->
        s = headers.hdrs["location"]
        |> parse_query_attibute("s")
        %{"session" => s}
      _ -> {:error, "Could not get session from auth endpoint"}
    end
  end

  @doc """
  Returns a url to redirect to when making an explicit authentication
  request.
  """
  @spec auth(String.t) :: String.t
  def auth(state) do
    query = Map.merge(%{state: state, response_type: "code"}, default_params())
    Application.get_env(:idq_auth, :endpoint) <> "auth?" <> URI.encode_query(query)
  end

  @doc """
  Returns a code from the location headers resulting from an auth request
  after the user as already implicitly authenticated. Code is then exchanged
  for an access token.
  """
  @spec iauth(String.t) :: %{"code": String.t} | {:error, String.t}
  def iauth(session) do
    query = Map.merge(%{s: session, response_type: "code"}, default_params())
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "auth?" <> URI.encode_query(query)) do
      %{status_code: 302, headers: headers} ->
        code = headers.hdrs["location"]
        |> parse_query_attibute("code")
        %{"code" => code}
      _ -> {:error, "Could not get code from implicit auth endpoint"}
    end
  end

  @doc """
  Returns a challenge for use in implicit authentication after a session has been
  created. If `raw` is `true` returns a bitsting representing a QR code, otherwise
  returns a string that should be encoded either as a QR code or used in a deep link
  to the idQ® mobile app.
  """
  @spec challenge(String.t, boolean) :: String.t | <<>> | {:error, String.t}
  def challenge(session, raw) do
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "challenge" <> (if raw, do: "/img", else: "") <> "?s=" <> session) do
      %{status_code: 200, body: body} -> body
      _ -> {:error, "Could not get challenge image"}
    end
  end

  @doc """
  Returns a session identifier that is associated with the passed push token.
  The push session is used to monitor query if a user has authenticated using
  delegated authentication.
  """
  @spec pauth(String.t) :: String.t | {:error, String.t}
  def pauth(push_token) do
    query = Map.merge(%{push_token: push_token, response_type: "code"}, default_params())
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "pauth?" <> URI.encode_query(query)) do
      %{status_code: 307, headers: headers} ->
        ps = headers.hdrs["location"]
        |> parse_query_attibute("ps")
        %{"push_session" => ps}
      _ -> {:error, "Could not get push session from pauth endpoint"}
    end
  end

  @doc """
  Returns a code from the location headers resulting from a push auth request
  after the user as already authenticated. Code is then exchanged for an access
  token.
  """
  @spec pauth(String.t, String.t) :: %{"code": String.t} | {:error, String.t}
  def pauth(push_token, push_session) do
    query = Map.merge(%{ps: push_session, push_token: push_token, response_type: "code"}, default_params())
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "pauth?" <> URI.encode_query(query)) do
      %{status_code: 302, headers: headers} ->
        code = headers.hdrs["location"]
        |> parse_query_attibute("code")
        %{"code" => code}
      _ -> {:error, "Could not get code from pauth endpoint"}
    end
  end

  @doc """
  Returns the status of authentication related to a delegated authentication request.

  Return values are:

  * 0 - Still waiting on authentication result
  * 1 - Authentication result available
  * 2 - Unkown error
  """
  @spec pstatus(String.t) :: map() | integer | {:error, String.t}
  def pstatus(push_token) do
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "pstatus?ps=" <> push_token) do
      %{status_code: 200, body: body} -> Poison.decode!(body)
      _ -> {:error, "Could not get status"}
    end
  end

  @doc """
  Initiates a delegated authentication request using a push notification. Returns the push token
  required to create a push session and to query push status.
  """
  @spec push(map()) :: map() | {:error, String.t}
  def push(query) do
    query = query
    |> Map.merge(%{client_secret: Application.get_env(:idq_auth, :client_secret)})
    |> Map.merge(default_params())

    case HTTPotion.post(Application.get_env(:idq_auth, :endpoint) <> "push", [body: URI.encode_query(query), headers: ["Content-Type": "application/x-www-form-urlencoded"]]) do
      %{status_code: 200, body: body} -> Poison.decode!(body)
      _ -> {:error, "Could not get push_token"}
    end
  end

  @doc """
  Returns the status of an implicit authentication request based on session.

  Return values are:

  * 0 - Still waiting on authentication result
  * 1 - Authentication result available
  """
  @spec status(String.t) :: map() | integer | {:error, String.t}
  def status(status) do
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "status?s=" <> status) do
      %{status_code: 200, body: body} -> Poison.decode!(body)
      _ -> {:error, "Could not get status"}
    end
  end

  @doc """
  Takes a code and returns the access token in an OAuth flow.
  """
  @spec token(String.t) :: map() | {:error, String.t}
  def token(code) do
    query = Map.merge(%{code: code, grant_type: "authorization_code", client_secret: Application.get_env(:idq_auth, :client_secret)}, default_params())
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "token?" <> URI.encode_query(query)) do
      %{status_code: 200, body: body} -> body |> Poison.decode!
      _ -> {:error, "Could not get access token"}
    end
  end

  @doc """
  Takes the access token and exchanges it for user information.
  """
  @spec user(String.t) :: map() | {:error, String.t}
  def user(token) do
    case HTTPotion.get(Application.get_env(:idq_auth, :endpoint) <> "user?access_token=" <> token) do
      %{status_code: 200, body: body} -> Poison.decode!(body)
      _ -> {:error, "Could not get user"}
    end
  end

  @spec default_params() :: %{redirect_uri: String.t, client_id: String.t}
  defp default_params do
    %{
      redirect_uri: Application.get_env(:idq_auth, :callback_url),
      client_id: Application.get_env(:idq_auth, :client_id),
    }
  end

  @spec parse_query_attibute(String.t, String.t) :: String.t
  defp parse_query_attibute(url, attr) do
    url
    |> URI.parse
    |> Map.get(:query)
    |> URI.decode_query
    |> Map.get(attr)
  end

end
