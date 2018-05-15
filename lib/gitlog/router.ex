defmodule Gitlog.Router do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  get "/" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts(body)
    :ok = Logger.info(body)

    conn
    |> send_resp(200, "Plug!")
  end

  post "/" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts(body)
    :ok = Logger.info(body)

    conn
    |> send_resp(200, "Plug!")
  end

  match _ do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    IO.puts(body)
    :ok = Logger.info(body)

    send_resp(conn, 404, "Not Found")
  end
end
