defmodule IdqAuth.ApiTest do
  use ExUnit.Case, async: false

  alias IdqAuth.Api

  describe "expected api responses" do
    setup [:expected_responses]

    test "auth/0 returns a map with session key/value" do
      assert is_map(Api.auth)
      assert Map.has_key?(Api.auth, "session")
      assert Api.auth["session"] == "SESSION"
    end

    test "auth/1 returns a URL to redirect to" do
      assert is_binary(Api.auth("state"))
      assert String.contains?(Api.auth("state"), Application.get_env(:idq_auth, :endpoint))
    end

    test "iauth/1 returns a map with code key/value" do
      assert is_map(Api.iauth("session"))
      assert Map.has_key?(Api.iauth("session"), "code")
      assert Api.iauth("session")["code"] == "CODE"
    end

    test "challenge/1 returns a string if raw is false" do
      assert is_binary(Api.challenge("session", false))
      assert Api.challenge("session", false) == "CHALLENGE"
    end

    test "challenge/1 returns a bitstring if raw is true" do
      assert is_bitstring(Api.challenge("session", true))
      assert Api.challenge("session", true) == <<>>
    end

    test "pauth/1 returns a map with push_session key/value" do
      assert is_map(Api.pauth("push_token"))
      assert Map.has_key?(Api.pauth("push_token"), "push_session")
      assert Api.pauth("push_token")["push_session"] == "PUSH_SESSION"
    end

    test "pauth/2 returns a map with code key/value" do
      assert is_map(Api.pauth("push_token", "push_session"))
      assert Map.has_key?(Api.pauth("push_token", "push_session"), "code")
      assert Api.pauth("push_token", "push_session")["code"] == "CODE"
    end

    test "push/1 returns a map with push_token key/value" do
      assert is_map(Api.push(%{"payload" => "payload"}))
      assert Map.has_key?(Api.push(%{"payload" => "payload"}), "push_token")
      assert Api.push(%{"payload" => "payload"})["push_token"] == "PUSH_TOKEN"
    end

    test "pstatus/1 returns an integer" do
      assert is_integer(Api.pstatus("push_session"))
      assert Api.pstatus("push_session") == 1
    end

    test "status/1 returns an integer" do
      assert is_integer(Api.status("session"))
      assert Api.status("session") == 1
    end

    test "token/1 returns an with access_token key/value" do
      assert is_map(Api.token("code"))
      assert Map.has_key?(Api.token("code"), "access_token")
      assert Api.token("code")["access_token"] == "TOKEN"
    end

    test "user/1 returns a map" do
      assert is_map(Api.user("token"))
    end
  end

  describe "unexpected api responses" do
    setup [:unexpected_responses]

    test "auth/0 returns an error tuple with message" do
      assert Api.auth == {:error, "Could not get session from auth endpoint"}
    end

    test "iauth/1 returns an error tuple with message" do
      assert Api.iauth("session") == {:error, "Could not get code from implicit auth endpoint"}
    end

    test "challenge/1 returns an error tuple with message" do
      assert Api.challenge("session", false) == {:error, "Could not get challenge image"}
    end

    test "pauth/1 returns an error tuple with message" do
      assert Api.pauth("push_token") == {:error, "Could not get push session from pauth endpoint"}
    end

    test "pauth/2 returns an error tuple with message" do
      assert Api.pauth("push_token", "push_session") == {:error, "Could not get code from pauth endpoint"}
    end

    test "push/1 returns an error tuple with message" do
      assert Api.push(%{"payload" => "payload"}) == {:error, "Could not get push_token"}
    end

    test "pstatus/1 returns an error tuple with message" do
      assert Api.pstatus("push_session") == {:error, "Could not get status"}
    end

    test "status/1 returns an error tuple with message" do
      assert Api.status("session") == {:error, "Could not get status"}
    end

    test "token/1 returns an error tuple with message" do
      assert Api.token("code") == {:error, "Could not get access token"}
    end

    test "user/1 returns an error tuple with message" do
      assert Api.user("token") == {:error, "Could not get user"}
    end
  end


  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
