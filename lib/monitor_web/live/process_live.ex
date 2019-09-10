defmodule Monitor.ProcessLive do
  use Phoenix.LiveView
  alias Monitor.Util
  alias Monitor.Alert

  def render(assigns) do
    ~L"""
    <header>
      <div class="container">
        <div class="clearfix">
          <h1 class="float-left">System Monitoring</h1>
          <div phx-click="menu-open" class="float-right svg-menu">
            <span>
              <%= if @menu_open do %>
                <i class="material-icons">menu_open</i>
              <% else %>
                <i class="material-icons">menu</i>
              <% end %>
            </span>
          </div>
        </div>
        <%= if @menu_open do %>
          <h3>Settings</h3>
          <form>
            <fieldset>
              <label for="threshold">Process Alert Threshold</label>
              <input phx-click="threshold" type="number" value="<%= @alert_threshold %>" min="1" max="100" id="threshold">

              <label for="alert-window">Alert Window Length</label>
              <input phx-click="alert-window" type="number" value="<%= @alert_window_length %>" min="1" id="alert-window">

              <label for="monitor-window">Monitor Window Length (in seconds)</label>
              <input phx-click="monitor-window" type="number" value="<%= @monitor_window_length %>" min="1" id="monitor-window">

              <p>
                An alert will be generated if the average process % tracked in the last
                <%= @alert_window_length * @monitor_window_length %> seconds is greater than or equal to
                <%= @alert_threshold %>%.
              </p>

              <label for="cpu-max">Simulate Heavy CPU Load</label>
              <input phx-click="cpu-max" type="checkbox" id="cpu-max" <%= if @simulation do %>checked <% end %>>
            </fieldset>
          </form>
        <% end %>
      </div>
    </header>

    <main role="main" class="container">
      <h3 class="header"> Process Utilization Percentage</h3>
      <%= if @simulation do %>
        <p class="alert alert-warning" role="alert">WARNING: Triggered Heavy CPU Load Simulation</p>
      <% end %>
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
          points="<%= @system_info |> Util.convert_data() %>"
        />
      </svg>

      <h3 class="header">Alert History</h3>
      <div>
        <%= if length(@alert_log) > 0 do %>
          <%= for {val, alert_timestamp, state, resolved_timestamp} <- @alert_log |> Enum.reverse() do  %>
            <p class="alert alert-<%= Atom.to_string(state) %>" role="alert">
              High load generated an alert - load = <%= val %>, triggered at time <%= alert_timestamp %>
              <%= if resolved_timestamp do %>
                - [Resolved at <%= resolved_timestamp %>]
              <% end %>
            </p>
          <% end %>
        <% else %>
          No alerts have been generated.
        <% end %>
      </div>

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
                  <%= s |> Keyword.get(:timestamp) %>
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
    </main>
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
        monitor_window_length: 10,
        loading_initial_data: true,
        menu_open: false,
        simulation: false,
        alert_threshold: 95,
        alert_log: [],
        alert_window_length: 12
      )
    }
  end

  def handle_info(
        :tick,
        %{
          assigns: %{
            system_info: system_info,
            process_window: process_window,
            monitor_window_length: monitor_window_length,
            alert_threshold: alert_threshold,
            alert_log: alert_log,
            alert_window_length: alert_window_length
          }
        } = socket
      )
      when length(process_window) == monitor_window_length do
    tick()

    {
      :noreply,
      assign(
        socket,
        system_info:
          Util.insert_data_point(
            system_info,
            Keyword.new([
              {:timestamp, Time.utc_now() |> Time.truncate(:second)},
              {:process_average,
               (Enum.sum(process_window) / monitor_window_length) |> Kernel.trunc()},
              {:free_memory, Util.free_memory()},
              {:used_memory, Util.used_memory()}
            ])
          ),
        process_window: [Util.cpu_util()],
        loading_initial_data: false,
        alert_log:
          Alert.process_logs(
            system_info,
            alert_log,
            alert_window_length,
            alert_threshold
          )
      )
    }
  end

  def handle_info(:tick, %{assigns: %{process_window: process_window}} = socket) do
    tick()
    {:noreply, assign(socket, process_window: process_window ++ [Util.cpu_util()])}
  end

  def handle_event("menu-open", _value, %{assigns: %{menu_open: menu_open}} = socket) do
    {:noreply, assign(socket, menu_open: menu_open |> Kernel.not())}
  end

  def handle_event("threshold", %{"value" => value}, socket) do
    {alert_threshold, _} = Integer.parse(value)
    {:noreply, assign(socket, alert_threshold: alert_threshold)}
  end

  def handle_event("alert-window", %{"value" => value}, socket) do
    {alert_window_length, _} = Integer.parse(value)
    {:noreply, assign(socket, alert_window_length: alert_window_length)}
  end

  def handle_event("monitor-window", %{"value" => value}, socket) do
    {monitor_window_length, _} = Integer.parse(value)

    {
      :noreply,
      assign(
        socket,
        monitor_window_length: monitor_window_length,
        process_window: [Util.cpu_util()]
      )
    }
  end

  def handle_event("cpu-max", _value, %{assigns: %{simulation: false}} = socket) do
    process_list =
      Util.cpu_util_per_cpu()
      |> Enum.map(fn _ ->
        spawn(fn -> Util.infinite_loop() end)
      end)

    {:noreply, assign(socket, simulation: true, simulated_processes: process_list)}
  end

  def handle_event(
        "cpu-max",
        _value,
        %{assigns: %{simulated_processes: simulated_processes}} = socket
      ) do
    Enum.map(simulated_processes, fn pid -> Process.exit(pid, :kill) end)
    {:noreply, assign(socket, simulation: false)}
  end

  defp tick() do
    self() |> Process.send_after(:tick, 1000)
  end
end
