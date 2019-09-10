defmodule Monitor.Alert do
  @moduledoc """
  Provides helper to compute the triggering of alerts within the monitor liveview
  """

  @doc """
  Process the alerts from the streamed system info data. Outputs a log of alert logs, given
  an alert window length and alert threshold
  """
  def process_logs(system_info, alert_log, alert_window_length, alert_threshold) do
    alert_window = get_alert_window(system_info, alert_window_length)

    if length(alert_window) == alert_window_length do
      avg = alert_window_average(alert_window)

      if avg >= alert_threshold do
        if get_latest_alert_state(alert_log) != :danger do
          alert_log ++ [{avg, Time.utc_now() |> Time.truncate(:second), :danger, nil}]
        else
          alert_log
        end
      else
        if get_latest_alert_state(alert_log) == :danger do
          resolve_latest_alert(alert_log)
        else
          alert_log
        end
      end
    else
      alert_log
    end
  end

  @doc """
  Get the latest window of (non nil) process metrics of the alert window length
  """
  def get_alert_window(system_info, alert_window_length) do
    system_info
    |> Enum.take(-1 * alert_window_length)
    |> Enum.filter(fn x -> x != nil end)
  end

  @doc """
  Given an alert window, calculate the average process metric in the length of the window
  """
  def alert_window_average(alert_window) do
    (Enum.reduce(
       alert_window,
       0,
       fn data, acc -> Keyword.get(data, :process_average) + acc end
     ) / length(alert_window))
    |> Kernel.trunc()
  end

  @doc """
  Get the latest alert state from the alert logs
  """
  def get_latest_alert_state(alert_log) do
    Enum.take(alert_log, -1)
    |> case do
      [] -> nil
      [{_, _, state, _}] -> state
    end
  end

  @doc """
  Give a log of alerts, resolve the latest alert, changing the state from :danger to :info
  """
  def resolve_latest_alert(alert_log) do
    {log, resolved_log} = List.pop_at(alert_log, -1)
    {avg, alert_timestamp, _, _} = log
    resolved_log ++ [{avg, alert_timestamp, :info, Time.utc_now() |> Time.truncate(:second)}]
  end
end
