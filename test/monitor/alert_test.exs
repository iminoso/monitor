defmodule Monitor.AlertTest do
  use ExUnit.Case, async: false
  alias Monitor.Alert

  describe "Alert Module" do
    test "should trigger an alert if the process avg in the alert window is greater than the threshold" do
      alert_log = []
      alert_window_length = 12
      alert_threshold = 100
      system_info = generate_system_log(100) |> List.duplicate(12)

      generated_alert_logs = Alert.process_alerts(system_info, alert_log, alert_window_length, alert_threshold)

      # Assert an alert was generated and added to the logs
      assert length(generated_alert_logs) == 1

      [{process_average, timestamp, state, recovery_timestamp}] = Enum.take(generated_alert_logs, -1)
      assert process_average >= alert_threshold
      assert is_timestamp_type(timestamp)
      assert state == :danger
      assert recovery_timestamp == nil

      system_info = system_info ++ [generate_system_log(0)]
      generated_alert_logs = Alert.process_alerts(system_info, generated_alert_logs, alert_window_length, alert_threshold)

      assert length(generated_alert_logs) == 1
      [{process_average, timestamp, state, recovery_timestamp}] = Enum.take(generated_alert_logs, -1)
      assert is_timestamp_type(timestamp)
      assert state == :info
      assert is_timestamp_type(recovery_timestamp)
    end
  end

  defp generate_system_log(process_average) do
    Keyword.new([
      {:timestamp, ~T[04:01:48]},
      {:process_average, process_average},
      {:free_memory, 610},
      {:used_memory, 1300}
    ])
  end

  defp is_timestamp_type(%Time{}), do: true
  defp is_timestamp_type(_), do: false
end
