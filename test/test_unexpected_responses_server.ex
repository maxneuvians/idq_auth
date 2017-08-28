defmodule IdqAuth.TestUnexpectedResponsesServer do
  use Plug.Router

  plug :match
  plug :dispatch

  def start_link do
    Plug.Adapters.Cowboy.http(IdqAuth.TestUnexpectedResponsesServer, [], port: 56566)
  end

  get "/*path" do
    conn
    |> send_resp(500, "Fatal Disk Error")
  end

  post "/*path" do
    conn
    |> send_resp(500, "Fatal Disk Error")
  end
end
