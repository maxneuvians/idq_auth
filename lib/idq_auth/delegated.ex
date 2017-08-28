defmodule IdqAuth.Delegated do
  @moduledoc """
  This module exposes the implicit delegated authorization flow. To
  initiate implicit delegated authorization you need to know the user_id
  of a user in the idQ® system. Authorization takes the form of a push message
  that the user receives on their device that has the idQ® app installed.

  The primary function `push/4` returns a GenServer that an application can use to
  monitor a users response to the push notification. The `GenServer` returns it's
  id which is either randomly generated or the fourth argument of the `push/4` function.

  Using the id the application can they query the push response status using
  `IdqAuth.Delegated.Observer.result/1`.
  """

  alias IdqAuth.{Api, Delegated.Observer}

  @doc """
  Initiates the implicit delegated authorization flow using a push notification.

  Takes the following arguments:

  * `target`  - The user_id of the user in the idQ® system
  * `title`   - The title of the push notification
  * `message` - The message body of the notification
  * `push_id` - An optional ID for the push notification. This will be reflected in the returned `GenServer` id

  Returns the following tuple `{:ok, pid, id}`:

  * `pid` - The PID of the GenServer process
  * `id`  - Global ID of the GenServer so you can query the result

  """
  @spec push(String.t, String.t, String.t, String.t | nil) :: {:ok, pid(), String.t} | {:error, String.t}
  def push(target, title, message, push_id \\ nil) do
    push_id = (if push_id != nil, do: push_id, else: UUID.uuid4)

    payload = %{
      target: target,
      message: message,
      title: title,
      push_id: push_id
    }

    with  %{"push_token" => push_token, "expires_in" => expires_in} <- Api.push(payload),
          %{"push_session" => push_session} <- Api.pauth(push_token)
    do
      Observer.start(push_id, push_session, push_token, expires_in)
    else
      {:error, msg} -> {:error, msg}
    end
  end

end
