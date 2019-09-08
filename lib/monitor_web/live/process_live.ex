defmodule Monitor.ProcessLive do
  use Phoenix.LiveView
  alias Monitor.Util

  @window_length 10

  def render(assigns) do
    ~L"""
    <h3 class="header"> Process Utilization Percentage</h3>
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
        points="<%= @system_info |> convert_data() %>"
      />
    </svg>
    <h3 class="header">Log History</h3>
    <table>
      <thead>
        <tr>
          <th>UTC Timestamp</th>
          <th>Process Utilization Percentage</th>
          <th>Memory Used</th>
          <th>Memory Available</th>
        </tr>
      </thead>
      <tbody>
      <%= unless @loading_initial_data do %>
        <%= for s <- @system_info |> Enum.reverse() do  %>
          <%= if s do %>
            <tr>
              <td>
                <%= s |> Keyword.get(:timestamp) |> Time.to_iso8601() %>
              </td>
              <td>
                <%= s |> Keyword.get(:process_average) %>
              </td>
              <td>
                <%= s |> Keyword.get(:used_memory) %> MB
              </td>
              <td>
                <%= s |> Keyword.get(:free_memory) %> MB
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
        system_info: List.duplicate(nil, 60),
        process_window: [],
        loading_initial_data: true
      )
    }
  end

  def handle_info(
        :tick,
        %{
          assigns: %{
            system_info: system_info,
            process_window: process_window
          }
        } = socket
      )
      when length(process_window) == @window_length do
    tick()

    {
      :noreply,
      assign(
        socket,
        system_info:
          insert_data_point(
            system_info,
            Keyword.new([
              {:timestamp, Time.utc_now() |> Time.truncate(:second)},
              {:process_average, (Enum.sum(process_window) / @window_length) |> Kernel.trunc()},
              {:free_memory, Util.free_memory()},
              {:used_memory, Util.used_memory()}
            ])
          ),
        process_window: [Util.cpu_util()],
        loading_initial_data: false
      )
    }
  end

  def handle_info(:tick, %{assigns: %{process_window: process_window}} = socket) do
    tick()
    {:noreply, assign(socket, process_window: process_window ++ [Util.cpu_util()])}
  end

  defp tick() do
    self() |> Process.send_after(:tick, 1000)
  end

  # Convert list into string of points accepted by `polyline` svg element
  defp convert_data(data_points) do
    str_points =
      Enum.with_index(data_points)
      |> Enum.map(fn {data_value, timestamp} ->
        data_value = if data_value == nil, do: 0, else: Keyword.get(data_value, :process_average)
        "#{timestamp * 10},#{200 - data_value * 2}"
      end)

    str_points |> Enum.join(" ")
  end

  # Add data point to end of list
  defp insert_data_point(data, val) do
    [_ | tail] = data
    tail ++ [val]
  end
end
