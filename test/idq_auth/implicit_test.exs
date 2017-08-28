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
      {:ok, challenge, pid, name} = start_challenge(false)
      assert is_binary(challenge)
      assert is_pid(pid)
      assert is_binary(name)
    end
  end

  describe "unexpected start_challenge/1" do
    setup [:unexpected_responses]

    test "returns a error tuple with message" do
      assert {:error, "Could not get session from auth endpoint"} = start_challenge(false)
    end
  end

  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
