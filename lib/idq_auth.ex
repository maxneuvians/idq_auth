defmodule IdqAuth do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    if length(check_config()) != 0 do
      raise "idQ Auth Plug is missing configuration variables, please check your logs"
    end

    children = []

    opts = [strategy: :one_for_one, name: IdqAuthPlug.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp check_config do
    [:endpoint, :callback_url, :client_id, :client_secret]
    |> Enum.filter(&(Application.get_env(:idq_auth, &1) == nil))
    |> Enum.map(fn key ->
      Logger.error("idQ Auth Plug: #{key} configuration key is missing")
      key
    end)
  end
end
