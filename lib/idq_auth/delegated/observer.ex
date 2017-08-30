defmodule IdqAuth.Delegated.Observer do
  @moduledoc """
  `GenServer` used in delegated authorization. Takes a `push_id`,
  `push_session`, `push_token`, `expires_in`, and a `callback` function
  to queries the idQ® servers every 2 seconds to see if delegated
  authorization has been completed.

  The GenServer will also execute a passed `callback` funciton with the
  result as the single argument if the callback is of arity `/1`. If a `callback`
  function with arity `/2` is passed then the second argument is the optional
  `context` argument

  Returns the `GenServer`'s pid so a developer can query the
  result using `GenServer.call(pid, :result)`. Once the result is retrieved
  calls the passed `callback` function with the result.

  The `GenServer` will terminate itself after `expires_in` seconds as
  that is the timeout for an delegated authorization challenge.
  """

  use GenServer
  alias IdqAuth.Api

  @check_interval 2_000

  # Public API

  @doc """
  Starts a new GenServer to monitor if delegated
  authorization has been completed.

  Takes the following arguments:

  * `session`  - The session that is being monitored
  * `callback` - A callback function that takes one argument once GenServer gets the result
  * `context`  - If your callback is of arity `/2` then the context will be passed as the second argument

  Returns {:ok, pid} where:

  * `pid` - The PID of the GenServer process
  """
  @spec start(String.t, String.t, integer, function(), any()) :: {:ok, pid()}
  def start(push_session, push_token, expires_in, callback, context) do
    GenServer.start_link(
      __MODULE__,
      %{
        push_session: push_session,
        push_token: push_token,
        ttl: expires_in * 1_000,
        result: 0,
        callback: callback,
        context: context
      })
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

      if is_function(state[:callback], 1) do
        state[:callback].(result)
      else
        state[:callback].(result, state[:context])
      end

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
