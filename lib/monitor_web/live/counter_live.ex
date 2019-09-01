defmodule Monitor.CounterLive do
  use Phoenix.LiveView

    def render(assigns) do
    ~L"""
    <div class="">
      <div>
        <%= @count %>
      </div>
    </div>
    """
  end

    def mount(_session, socket) do
    tick()
    {:ok, assign(socket, count: 0)}
  end

    def handle_info(:tick, socket) do
    tick()
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

    defp tick() do
    self() |> Process.send_after(:tick, 500)
  end
end
