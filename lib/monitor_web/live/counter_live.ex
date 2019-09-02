defmodule Monitor.CounterLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <svg viewBox="0 0 500 200" class="chart">

    <polyline
      fill="none"
      stroke="#0074d9"
      stroke-width="2"
      points="<%= @process_data |> convert_data() %>"
    />

    </svg>
    <div class="">
      <div>
        <%= @process_data |> Enum.join(" ") %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    tick()
    {:ok, assign(socket, process_data: [0,0,0,0,0,0,0,0,0,0])}
  end

  def handle_info(:tick, %{assigns: %{process_data: process_data}} = socket) do
    tick()
    cpu_util = :cpu_sup.util() |> Kernel.trunc()
    {:noreply, assign(socket, process_data: insert_data_point(process_data, cpu_util))}
  end

  defp tick() do
    self() |> Process.send_after(:tick, 1000)
  end

  # Convert list into string of points accepted by `polyline` element
  defp convert_data(points) do
    str_points = Enum.with_index(points) |> Enum.map(fn {y,x} ->
      "#{x * 20},#{(100 - y)}"
    end)
    str_points |> Enum.join(" ")
  end

  # Add data point to end
  defp insert_data_point(data, val) do
    [_ | tail] = data
    tail ++ [val]
  end
end
