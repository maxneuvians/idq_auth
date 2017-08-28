defmodule IdqAuth.DelegatedObserverTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Delegated.Observer

  describe "expected result/1" do
    setup [:expected_responses, :start_server]

    test "returns a user map from state of GenServer", %{id: id} do
      assert is_map(result(id))
      assert result(id) == %{"email" => "EMAIL"}
    end
  end

  describe "unexpected result/1" do
    setup [:unexpected_responses, :start_server]

    test "returns 0 to indicate no respinse recieved", %{id: id} do
      assert is_integer(result(id))
      assert result(id) == 0
    end
  end

  describe "start/4" do

    test "returns a tuple with :ok atom, pid, and ID name" do
      {:ok, pid, name} = start("ID", "TITLE", "MESSAGE", 10)
      assert is_pid(pid)
      assert is_binary(name)
      assert name == "push-ID"
    end
  end


  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp start_server(_context) do
    {:ok, _pid, id} = start("ID", "TITLE", "MESSAGE", 10)
    {:ok, %{id: id}}
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
