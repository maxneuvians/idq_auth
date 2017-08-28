defmodule IdqAuth.Plug do
  @moduledoc """
  A plug that uses explicit idQ® TaaS Authentication from inBay Technologies Inc.

  The plug executes an OAuth token exchange after a user has
  authenticated through the idQ® service. If authentication is successful
  the user's profile data is added to the `assigns` map as part of the
  `conn` struct using the `idq_user` atom.
  """

  alias IdqAuth.Explicit

  @doc """
  Init function required for all plugs
  """
  @spec init(list) :: list
  def init(options), do: options

  @doc """
  Call function that executes explicit authentication for `conn`
  """
  @spec call(%Plug.Conn{}, list) :: %Plug.Conn{}
  def call(conn, _opts), do: Explicit.authenticate(conn)

end
