defmodule IdqAuth.Implicit do
  @moduledoc """
  This module exposes the implicit authorization flow. It allows an application
  to create a challenge, either in form of a unique string, or a QR encoded version
  of that unique string, which is then presented to the user for authentication. If
  the challenge is being presented on a device that has the idQ® application installed,
  the user may choose to use a deep-link to access the application directly.

  The primary function `start_challenge/1` returns a GenServer that an application can use to
  monitor a users response to the implicit authorization flow.

  The GenServer will also execute a passed `callback` funciton with the
  result as the single argument if the callback is of arity `/1`. If a `callback`
  function with arity `/2` is passed then the second argument is the optional
  `context` argument

  Using the pid the application can they query the implicit authorization response status using
  `IdqAuth.Implicit.result/1`.
  """

  alias IdqAuth.{Api, Implicit.Observer}

  @doc """
  Returns a string formated as a deep-link for direct access to the idQ® application installed
  on the user's device.
  """
  @spec deep_link(String.t) :: String.t
  def deep_link(challenge) do
    "com.inbaytech.idqconnect:///authentication/" <> challenge
  end

  @doc """
  Starts the implicit authorization flow. Takes a boolean to determin if the challenge
  is returned as a string or as a bitstring that represents the QR image of the challenge
  string.

  Takes the following arguments:

  * `callback` - A callback function that takes one argument once GenServer gets the result
  * `raw`      - If `false`, then the application should either encode the string as a QR image or user `deep_link/1` to create a direct link to the user's idQ® application.
  * `context`  - If your callback is of arity `/2` then the context will be passed as the second argument

  Returns the following tuple `{:ok, challenge, pid}`:

  * `challenge` - The challenge to expose to the user trying to authenticate
  * `pid` - The PID of the GenServer process
  """
  @spec start_challenge(function(), boolean, any()) :: {:ok, String.t | <<>>, pid()}
  def start_challenge(callback, raw \\ false, context \\ %{}) do
    with  %{"session" => session} <- Api.auth,
          challenge <- Api.challenge(session, raw),
          {:ok, pid} <- Observer.start(session, callback, context)
    do
      {:ok, challenge, pid}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Takes a pid and queries the result from the associated `GenServer`.
  The result is the state of the implicit authorization.
  """
  @spec result(pid()) :: {integer | map()}
  def result(pid) do
    GenServer.call(pid, :result)
  end

end
