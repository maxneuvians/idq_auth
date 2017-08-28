defmodule IdqAuth.DelegatedTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Delegated

  describe "expected push/1" do
    setup [:expected_responses]

    test "returns a tuple with :ok, pid, and genserver name" do
      {:ok, pid, name} = push("target", "title", "message", "id")
      assert is_pid(pid)
      assert is_binary(name)
    end
  end

  describe "unexpected push/1" do
    setup [:unexpected_responses]

    test "returns a error tuple with message" do
      assert {:error, "Could not get push_token"} = push("target", "title", "message", "id")
    end
  end

  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
