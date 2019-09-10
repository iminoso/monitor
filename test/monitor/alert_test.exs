defmodule Monitor.AlertTest do
  use ExUnit.Case, async: false
  alias Monitor.Alert

  describe "Alert Module" do
    test "should trigger an alert if the process avg in the alert window is greater than the threshold" do
      # Initalize alert logs, window length and the threshold to trigger and alert
      alert_log = []
      alert_window_length = 12
      alert_threshold = 100

      # Mock a set of system logs on heavy load with an average process tracked of 100
      system_info = generate_system_log(100) |> List.duplicate(12)

      # Test the Alert module processing the logs
      generated_alert_logs = Alert.process_logs(system_info, alert_log, alert_window_length, alert_threshold)

      # Assert an alert was generated and added to the logs
      assert length(generated_alert_logs) == 1

      # Check the alert logs for the latest alert, assert the alert is correctly formatted
      [{process_average, timestamp, state, recovery_timestamp}] = Enum.take(generated_alert_logs, -1)
      assert process_average >= alert_threshold
      assert is_timestamp_type(timestamp)
      assert state == :danger
      assert recovery_timestamp == nil

      # Add a new log that drops the process average below the threshold
      system_info = system_info ++ [generate_system_log(0)]
      generated_alert_logs = Alert.process_logs(system_info, generated_alert_logs, alert_window_length, alert_threshold)

      # Assert the alert that was triggered is resolved
      assert length(generated_alert_logs) == 1
      [{_process_average, timestamp, state, recovery_timestamp}] = Enum.take(generated_alert_logs, -1)
      assert is_timestamp_type(timestamp)
      assert state == :info
      assert is_timestamp_type(recovery_timestamp)

      # Generate a another set of 100 percent average high load average, assert a new distinct
      # alert is called
      system_info = system_info ++ generate_system_log(100) |> List.duplicate(12)
      generated_alert_logs = Alert.process_logs(system_info, generated_alert_logs, alert_window_length, alert_threshold)
      assert length(generated_alert_logs) == 2
    end
  end

  # Helper function to create a properly formated log
  defp generate_system_log(process_average) do
    Keyword.new([
      {:timestamp, ~T[04:01:48]},
      {:process_average, process_average},
      {:free_memory, 610},
      {:used_memory, 1300}
    ])
  end

  # Helper function to check if the variable is a Time type
  defp is_timestamp_type(%Time{}), do: true
  defp is_timestamp_type(_), do: false
end
