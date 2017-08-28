defmodule IdqAuth.Implicit do
  @moduledoc """
  This module exposes the implicit authorization flow. It allows an application
  to create a challenge, either in form of a unique string, or a QR encoded version
  of that unique string, which is then presented to the user for authentication. If
  the challenge is being presented on a device that has the idQ® application installed,
  the user may choose to use a deep-link to access the application directly.

  The primary function `start_challenge/1` returns a GenServer that an application can use to
  monitor a users response to the implicit authorization flow. The `GenServer` returns it's
  id which is randomly generated.

  Using the id the application can they query the implicit authorization response status using
  `IdqAuth.Implicit.Observer.result/1`.
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

  If `raw` is `false`, then the application should either encode the string as a QR image
  or user `deep_link/1` to create a direct link to the user's idQ® application.

  Returns the following tuple `{:ok, challenge, pid, id}`:

  * `challenge` - The challenge to expose to the user trying to authenticate
  * `pid` - The PID of the GenServer process
  * `id`  - Global ID of the GenServer so you can query the result
  """
  @spec start_challenge(boolean) :: {:ok, String.t | <<>>, pid(), String.t}
  def start_challenge(raw \\ false) do
    with  %{"session" => session} <- Api.auth,
          challenge <- Api.challenge(session, raw),
          {:ok, pid, id} <- Observer.start(session)
    do
      {:ok, challenge, pid, id}
    else
      {:error, msg} -> {:error, msg}
    end
  end

end
