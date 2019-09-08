defmodule Monitor.ProcessLive do
  use Phoenix.LiveView
  alias Monitor.Util

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
        points="<%= @process_info |> convert_data() %>"
      />
    </svg>

    <table>
      <thead>
        <tr>
          <th>Timestamp</th>
          <th>Process Utilization %</th>
          <th>Memory Used</th>
          <th>Memory Available</th>
        </tr>
      </thead>
      <tbody>
      <%= unless @loading_initial_data do %>
        <%= for {p, index} <- Enum.with_index(@process_info) do  %>
          <%= if p do %>
            <tr>
              <td>
                <%= @timestamp |> Enum.at(index) |> Time.to_iso8601() %>
              </td>
              <td>
                <%= @process_info |> Enum.at(index) %>
              </td>
              <td>
                <%= @memory_info |> Enum.at(index) |> Keyword.get(:used_memory) %> MB
              </td>
              <td>
                <%= @memory_info |> Enum.at(index) |> Keyword.get(:free_memory) %> MB
              </td>
            </tr>
          <% end %>
        <% end %>
      <% end %>
      </tbody>
    </table>

    <%= if @loading_initial_data do %>
      Loading system data <%= for _ <- @process_window do %> . <% end %>
    <% end %>
    """
  end

  def mount(_session, socket) do
    tick()
    {
      :ok,
      assign(
        socket,
        process_info: List.duplicate(nil, 60),
        memory_info: List.duplicate(nil, 60),
        process_window: [],
        timestamp: List.duplicate(nil, 60),
        loading_initial_data: true
      )
    }
  end

  def handle_info(:tick, %{assigns: %{process_info: process_info, memory_info: memory_info, timestamp: timestamp, process_window: process_window}} = socket)
    when length(process_window) == 9
  do
    tick()
    process_window = process_window ++ [Util.cpu_util]
    {
      :noreply,
      assign(
        socket,
        process_info: insert_data_point(process_info, Enum.sum(process_window) / 10),
        memory_info: insert_data_point(
          memory_info,
          Keyword.new(
            [{:free_memory, Util.free_memory()}, {:used_memory, Util.used_memory()}]
          )
        ),
        process_window: [],
        timestamp: insert_data_point(timestamp, Time.utc_now() |> Time.truncate(:second)),
        loading_initial_data: false
      )
    }
  end

  def handle_info(:tick, %{assigns: %{process_window: process_window}} = socket) do
    tick()
    {:noreply, assign(socket, process_window: process_window ++ [Util.cpu_util])}
  end

  defp tick() do
    self() |> Process.send_after(:tick, 1000)
  end

  # Convert list into string of points accepted by `polyline` svg element
  defp convert_data(points) do
    str_points = Enum.with_index(points) |> Enum.map(fn {y,x} ->
      y = if (y == nil), do: 0, else: y
      "#{x * 10},#{(200 - (y * 2))}"
    end)
    str_points |> Enum.join(" ")
  end

  # Add data point to end of list
  defp insert_data_point(data, val) do
    [_ | tail] = data
    tail ++ [val]
  end
end
