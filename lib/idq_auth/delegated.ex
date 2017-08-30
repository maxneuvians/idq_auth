defmodule IdqAuth.Delegated do
  @moduledoc """
  This module exposes the implicit delegated authorization flow. To
  initiate implicit delegated authorization you need to know the user_id
  of a user in the idQ® system. Authorization takes the form of a push message
  that the user receives on their device that has the idQ® app installed.

  The primary function `push/4` returns a GenServer that an application can use to
  monitor a users response to the push notification by querying the GenServer
  `GenServer.call(pid, :result)`.

  The GenServer will also execute a passed `callback` funciton with the
  result as the single argument if the callback is of arity `/1`. If a `callback`
  function with arity `/2` is passed then the second argument is the optional
  `context` argument
  """

  alias IdqAuth.{Api, Delegated.Observer}

  @doc """
  Initiates the implicit delegated authorization flow using a push notification.

  Takes the following arguments:

  * `target`   - The user_id of the user in the idQ® system
  * `title`    - The title of the push notification
  * `message`  - The message body of the notification
  * `callback` - A callback function that takes one argument once GenServer gets the result
  * `context`  - If your callback is of arity `/2` then the context will be passed as the second argument

  Returns the following tuple `{:ok, pid, id}`:

  * `pid` - The PID of the GenServer process

  """
  @spec push(String.t, String.t, String.t, function(), any) :: {:ok, pid()} | {:error, String.t}
  def push(target, title, message, callback, context \\ %{}) do

    payload = %{
      target: target,
      message: message,
      title: title,
      push_id: UUID.uuid4
    }

    with  %{"push_token" => push_token, "expires_in" => expires_in} <- Api.push(payload),
          %{"push_session" => push_session} <- Api.pauth(push_token)
    do
      Observer.start(push_session, push_token, expires_in, callback, context)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Takes a pid and queries the result from the associated `GenServer`. The result
  is the state of the implicit delegated authorization.
  """
  @spec result(pid()) :: {integer | map()}
  def result(pid), do: GenServer.call(pid, :result)

end
