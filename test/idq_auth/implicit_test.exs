defmodule IdqAuth.ImplicitTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Implicit

  describe "deep_link/1" do

    test "returns a string representing a deep link for mobile applications" do
      assert is_binary(deep_link("ABCD"))
      assert deep_link("ABCD") =~ "com.inbaytech.idqconnect:///authentication/"
    end

  end

  describe "expected start_challenge/1" do
    setup [:expected_responses]

    test "returns a tuple with :ok atom, challenge, pid, and genserver name" do
      {:ok, challenge, pid} = start_challenge(&callback/1, false)
      assert is_binary(challenge)
      assert is_pid(pid)
    end
  end

  describe "unexpected start_challenge/1" do
    setup [:unexpected_responses]

    test "returns a error tuple with message" do
      assert {:error, "Could not get session from auth endpoint"} = start_challenge(&callback/1, false)
    end
  end

  describe "expected result/1" do
    setup [:expected_responses]

    test "returns a map with details of the user" do
      {:ok, challenge, pid} = start_challenge(&callback/1, false)
      assert is_binary(challenge)
      assert is_map(result(pid))
      assert result(pid) == %{"email" => "EMAIL"}
    end
  end

  describe "unexpected result/1" do
    setup [:unexpected_responses]

    test "returns an error message" do
      assert {:error, "Could not get session from auth endpoint"} = start_challenge(&callback/1, false)
    end
  end

  defp callback(_result) do
    true
  end

  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
