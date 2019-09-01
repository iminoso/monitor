defmodule MonitorWeb.PageController do
  use MonitorWeb, :controller
  alias Phoenix.LiveView

  def index(conn, _params) do
    LiveView.Controller.live_render(conn, Monitor.CounterLive, session: %{})
  end
end
