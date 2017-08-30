defmodule IdqAuth.DelegatedTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Delegated

  describe "expected push/1" do
    setup [:expected_responses]

    test "returns a tuple with :ok, pid, and genserver name" do
      {:ok, pid} = push("target", "title", "message", &callback/1)
      assert is_pid(pid)
    end
  end

  describe "unexpected push/1" do
    setup [:unexpected_responses]

    test "returns a error tuple with message" do
      assert {:error, "Could not get push_token"} = push("target", "title", "message", &callback/1)
    end
  end

  describe "expected result/1" do
    setup [:expected_responses]

    test "returns a map with details of the user" do
      {:ok, pid} = push("target", "title", "message",&callback/1)
      assert is_map(result(pid))
      assert result(pid) == %{"email" => "EMAIL"}
    end
  end

  describe "unexpected result/1" do
    setup [:unexpected_responses]

    test "returns an error message" do
      assert {:error, "Could not get push_token"} = push("target", "title", "message", &callback/1)
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
