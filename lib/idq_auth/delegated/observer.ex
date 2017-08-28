defmodule IdqAuth.Delegated.Observer do
  @moduledoc """
  `GenServer` used in delegated authorization. Takes a `push_id`,
  `push_session`, `push_token`, and `expires_in` to
  queries the idQ® servers every 2 seconds to see if delegated
  authorization has been completed. Registers the `GenServer` with
  a global id that can be used to query the result of the implicit
  authorization using the `result/1` function.

  The `GenServer` will terminate itself after `expires_in` seconds as
  that is the timeout for an delegated authorization challenge.
  """

  use GenServer
  alias IdqAuth.Api

  @check_interval 2_000

  # Public API

  @doc """
  Returns the result field of the `GenServer`'s state.
  Expects the global ID of a specific `GenServer` to query.
  """
  @spec result(String.t) :: {integer | map()}
  def result(id) do
    GenServer.call({:global, id}, :result)
  end

  @doc """
  Starts a new GenServer to monitor if delegated
  authorization has been completed. Returns
  {:ok, pid, id} where:

  * `pid` - The PID of the GenServer process
  * `id`  - Global ID of the GenServer so you can query the result
  """
  @spec start(String.t, String.t, String.t, integer) :: {:ok, pid(), String.t}
  def start(push_id, push_session, push_token, expires_in) do
    id = "push-#{push_id}"
    {:ok, pid} = GenServer.start_link(
      __MODULE__,
      %{
        push_session: push_session,
        push_token: push_token,
        ttl: expires_in * 1_000,
        result: 0
      },
      name: {:global, id})
    {:ok, pid, id}
  end

  # Private API

  @spec init(map()) :: {:ok, map()}
  def init(state) do
    send self(), :tick
    {:ok, state}
  end

  @spec handle_call(:result, {pid(), any}, map()) :: {:reply, integer | map(), map()}
  def handle_call(:result, _from, state), do: {:reply, state[:result], state}

  @spec handle_cast(:check_result, map()) :: {:noreply, map()}
  def handle_cast(:check_result, state) do
    with  0 <- state[:result],
          1 <- Api.pstatus(state[:push_token]),
          %{"code" => code} <- Api.pauth(state[:push_token], state[:push_session])
    do
      result = code
      |> Api.token()
      |> Map.get("access_token")
      |> Api.user()
      {:noreply, Map.put(state, :result, result)}
    else
      2 -> {:noreply, Map.put(state, :result, 2)}
      _ -> {:noreply, state}
    end
  end

  @spec handle_info(:tick, map()) :: {:noreply, map()} | {:stop, :normal, map()}
  def handle_info(:tick, state) do
    if state[:ttl] <= 0 do
      {:stop, :normal, state}
    else
      GenServer.cast(self(), :check_result)
      Process.send_after(self(), :tick, @check_interval)
      {:noreply, Map.put(state, :ttl, state[:ttl] - @check_interval)}
    end
  end

end
