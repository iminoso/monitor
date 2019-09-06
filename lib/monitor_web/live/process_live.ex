defmodule Monitor.ProcessLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <h3>System Process Utilization Percentage</h3>
    <svg viewBox="0 0 600 200" class="chart">
      <line x1="0" y1="150" x2="600" y2="150" stroke="#555" stroke-width="1" stroke-dasharray="2" />
      <line x1="0" y1="100" x2="600" y2="100" stroke="#555" stroke-width="1" stroke-dasharray="2" />
      <line x1="0" y1="50" x2="600" y2="50" stroke="#555" stroke-width="1" stroke-dasharray="2" />
      <text x="0" y="150" class="chart__label">25</text>
      <text x="0" y="100" class="chart__label">50</text>
      <text x="0" y="50" class="chart__label">75</text>
      <polyline
        fill="none"
        stroke="#00749d"
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
    {
      :ok,
      assign(
        socket,
        process_data: List.duplicate(0, 60),
        process_window: []
      )
    }
  end

  def handle_info(:tick, %{assigns: %{process_data: process_data, process_window: process_window}} = socket) do
    tick()
    cpu_util = :cpu_sup.util() |> Kernel.trunc()
    process_window = process_window ++ [cpu_util]

    if length(process_window) == 10 do
      process_data = insert_data_point(process_data, Enum.sum(process_window) / 10)
      process_window = []
      {:noreply, assign(socket, process_data: process_data, process_window: process_window)}
    else
      {:noreply, assign(socket, process_data: process_data, process_window: process_window)}
    end
  end

  defp tick() do
    self() |> Process.send_after(:tick, 1000)
  end

  # Convert list into string of points accepted by `polyline` element
  defp convert_data(points) do
    str_points = Enum.with_index(points) |> Enum.map(fn {y,x} ->
      "#{x * 10},#{(200 - (y * 2))}"
    end)
    str_points |> Enum.join(" ")
  end

  # Add data point to end
  defp insert_data_point(data, val) do
    [_ | tail] = data
    tail ++ [val]
  end
end
