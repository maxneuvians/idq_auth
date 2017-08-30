defmodule IdqAuth.ImplicitObserverTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import IdqAuth.Implicit.Observer

  describe "expected result with callback arity one" do
    setup [:expected_responses, :start_server_arity_one]

    test "returns a user map from state of GenServer", %{pid: pid} do
      assert is_map(GenServer.call(pid, :result))
      assert GenServer.call(pid, :result) == %{"email" => "EMAIL"}
    end
  end

  describe "expected result with callback arity two" do
    setup [:expected_responses, :start_server_arity_two]

    test "returns a user map from state of GenServer", %{pid: pid} do
      assert is_map(GenServer.call(pid, :result))
      assert GenServer.call(pid, :result) == %{"email" => "EMAIL"}
    end
  end

  describe "unexpected result/1" do
    setup [:unexpected_responses, :start_server_arity_one]

    test "returns 0 to indicate no respinse recieved", %{pid: pid} do
      assert is_integer(GenServer.call(pid, :result))
      assert GenServer.call(pid, :result) == 0
    end
  end

  describe "start/1" do

    test "returns a tuple with :ok atom, and pid" do
      {:ok, pid} = start("SESSION", &callback_arity_one/1, %{})
      assert is_pid(pid)
    end
  end

  defp callback_arity_one(result) do
    assert result == %{"email" => "EMAIL"}
  end

  defp callback_arity_two(result, context) do
    assert result == %{"email" => "EMAIL"}
    assert context == %{"context" => "CONTEXT"}
  end
  defp expected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56565/")
  end

  defp start_server_arity_one(_context) do
    {:ok, pid} = start("SESSION", &callback_arity_one/1, %{})
    {:ok, %{pid: pid}}
  end

  defp start_server_arity_two(_context) do
    {:ok, pid} = start("SESSION", &callback_arity_two/2, %{"context" => "CONTEXT"})
    {:ok, %{pid: pid}}
  end

  defp unexpected_responses(_context) do
    Application.put_env(:idq_auth, :endpoint, "http://localhost:56566/")
  end
end
