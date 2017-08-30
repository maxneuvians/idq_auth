defmodule IdqAuth.Implicit.Observer do
  @moduledoc """
  `GenServer` used in implicit authorization. Takes a `session` and
  queries the idQ® servers every 2 seconds to see if implicit
  authorization has been completed. Registers the `GenServer` with
  a global id that can be used to query the result of the implicit
  authorization using the `result/1` function.

  The `GenServer` will terminate itself after 20 seconds as that is
  the timeout for an implicit authorization challenge.
  """

  use GenServer
  alias IdqAuth.Api

  require Logger

  @check_interval 2_000

  # Public API

  @doc """
  Starts a new GenServer to monitor if implicit
  authorization has been completed. Returns
  {:ok, pid} where:

  * `pid` - The PID of the GenServer process
  """
  @spec start(String.t, function, any()) :: {:ok, pid()}
  def start(session, callback, context) do
    GenServer.start_link(
      __MODULE__,
      %{
        session: session,
        ttl: 20_000,
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
          1 <- Api.status(state[:session]),
          %{"code" => code} <- Api.iauth(state[:session])
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
