defmodule IdqAuth.PlugTest do
  use ExUnit.Case, async: false
  use Plug.Test

  @opts IdqAuth.Plug.init([])
  @session_opts Plug.Session.init([store: :cookie, key: "_idq_auth_key", signing_salt: "+++++++"])

  setup do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  describe "expected call/2" do
    setup [:expected_responses]

    test "redirects to idQ login page code and state params do not exist" do
      conn = prepare_connection("/")
      |> IdqAuth.Plug.call(@opts)

      assert conn.state == :sent
      assert conn.status == 302
      assert conn.resp_body =~ Application.get_env(:idq_auth, :endpoint)
    end

    test "returns a conn with an idq_user assigned if one time token is correct" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "EFGH")
      |> IdqAuth.Plug.call(@opts)

      assert is_map(conn.assigns[:idq_user])
    end
  end

  describe "unexpected call/2" do
    setup [:unexpected_responses]

    test "returns a conn with a 400 error even if one time token is correct" do
      conn = prepare_connection("/")
      |> Map.put(:params, %{"code" => "ABCD", "state" => "EFGH"})
      |> put_session(:idq_auth_token, "EFGH")
      |> IdqAuth.Plug.call(@opts)

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
