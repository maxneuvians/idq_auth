defmodule IdqAuth.ExplicitTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Explicit

  @session_opts Plug.Session.init([store: :cookie, key: "_idq_auth_key", signing_salt: "+++++++"])

  describe "expected authenticate/1" do
    setup [:expected_responses]

    test "redirects to idQ login page code and state params exist" do
      conn = prepare_connection("/")
      |> authenticate

      assert conn.state == :sent
      assert conn.status == 302
      assert conn.resp_body =~ Application.get_env(:idq_auth, :endpoint)
    end

    test "fails if one time token is invalid" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "IJKL")
      |> authenticate

      assert conn.state == :sent
      assert conn.status == 400
    end

    test "returns a conn with an idq_user assigned in case of correct one time token" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "EFGH")
      |> authenticate

      assert is_map(conn.assigns[:idq_user])
    end

    test "removes the one time token from session if correct" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "EFGH")
      |> authenticate

      assert get_session(conn, :idq_auth_token) == nil
    end

    test "removes the one time token from session if incorrect" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "IJKL")
      |> authenticate

      assert get_session(conn, :idq_auth_token) == nil
    end
  end

  describe "unexpected authenticate/1" do
    setup [:unexpected_responses]

    test "fails if server give unexpected response" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "EFGH")
      |> authenticate

      assert conn.state == :sent
      assert conn.status == 400
    end
  end

  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp prepare_connection(path) do
    conn(:get, path)
    |> Map.put(:secret_key_base, "kLJIWK9/hyXSGE+hrPEXIrxL9ew09IyfLOZ03koyG0IBNVo9h9CJ+PouahJltQ90")
    |> Plug.Session.call(@session_opts)
    |> fetch_session
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
