defmodule MonitorWeb.PageControllerTest do
  use MonitorWeb.ConnCase
  use Phoenix.ConnTest
  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ "System Monitoring"
  end
end
