defmodule IdqAuth.TestExpectedResponsesServer do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  def start_link do
    Plug.Adapters.Cowboy.http(IdqAuth.TestExpectedResponsesServer, [], port: 56565)
  end

  get "/auth" do
    case conn.params do
      %{"client_id" => _client_id, "redirect_uri" => _uri, "response_type" => "code", "s" => _session} ->
        conn
        |> put_resp_header("location", "http://localhost/?code=CODE")
        |> send_resp(302, "")
      %{"client_id" => _client_id, "redirect_uri" => _uri, "response_type" => "code"} ->
        conn
        |> put_resp_header("location", "http://localhost/?s=SESSION")
        |> send_resp(307, "")
      _ ->
        conn
        |> send_resp(404, "")
    end
  end

  get "challenge/img" do
    conn
    |> send_resp(200, <<>>)
  end

  get "challenge" do
    conn
    |> send_resp(200, "CHALLENGE")
  end

  get "/pauth" do
    case conn.params do
      %{"client_id" => _client_id, "redirect_uri" => _uri, "response_type" => "code", "push_token" => _push_token,  "ps" => _push_session} ->
        conn
        |> put_resp_header("location", "http://localhost/?code=CODE")
        |> send_resp(302, "")
      %{"client_id" => _client_id, "redirect_uri" => _uri, "response_type" => "code", "push_token" => _push_token} ->
        conn
        |> put_resp_header("location", "http://localhost/?ps=PUSH_SESSION")
        |> send_resp(307, "")
      _ ->
        conn
        |> send_resp(404, "")
    end

  end

  get "/pstatus" do
    conn
    |> send_resp(200, "1")
  end

  post "/push" do
    conn
    |> send_resp(200, "{\"push_token\": \"PUSH_TOKEN\", \"expires_in\": 10}")
  end

  get "/status" do
    conn
    |> send_resp(200, "1")
  end

  get "/token" do
    conn
    |> send_resp(200, "{\"access_token\": \"TOKEN\"}")
  end

  get "/user" do
    conn
    |> send_resp(200, "{\"email\": \"EMAIL\"}")
  end
end
