defmodule GitlogTest.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Gitlog.Router.init([])

  test "returns Plug!" do
    conn = conn(:get, "/")

    conn = Gitlog.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Plug!"
  end
end
