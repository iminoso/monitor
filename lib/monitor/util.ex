defmodule Monitor.Util do
  @moduledoc """
  Provides helper functions to track system metrics

  ## Examples
      iex> Monitor.Util.cpu_util()
      34
  """

  @doc """
  Calculates cpu utilization percentage, rounding to nearest integer
  """
  def cpu_util() do
    :cpu_sup.util()
    |> Kernel.trunc()
  end

  @doc """
  Returns the cpu usage of the system per cpu
  """
  def cpu_util_per_cpu() do
    :cpu_sup.util([:per_cpu])
  end

  @doc """
  Calculates the total amount of memory available to the Erlang emulator in MB
  """
  def total_memory() do
    system_memory_data() |> Keyword.get(:total_memory)
  end

  @doc """
  Calculates the amount of free memory available in MB
  """
  def free_memory() do
    system_memory_data() |> Keyword.get(:free_memory)
  end

  @doc """
  The amount of memory in use to by the application in MB
  """
  def used_memory() do
    total_memory() - free_memory()
  end

  @doc """
  The amount of memory available to the whole operating system in MB
  """
  def system_total_memory() do
    system_memory_data() |> Keyword.get(:system_total_memory)
  end

  @doc """
  Calculates memory of the system returning a keyword list of the form in MB:
  eg. [total_memory: _, free_memory: _, system_total_memory: _]
  """
  def system_memory_data() do
    :memsup.get_system_memory_data()
    |> Keyword.new(fn {k, v} -> {k, (v / 1_000_000) |> Kernel.trunc()} end)
  end

  @doc """
  Convert list into string of points accepted by `polyline` svg element
  """
  def convert_data(data_points) do
    str_points =
      Enum.with_index(data_points)
      |> Enum.map(fn {data_value, timestamp} ->
        data_value = if data_value == nil, do: 0, else: Keyword.get(data_value, :process_average)
        "#{timestamp * 10},#{200 - data_value * 2}"
      end)

    str_points |> Enum.join(" ")
  end

  @doc """
  Convert list into string of points accepted by `polyline` svg element
  """
  def insert_data_point(data, val) do
    [_ | tail] = data
    tail ++ [val]
  end

  @doc """
  Infinite loop that is forked to simulate CPU load
  """
  def infinite_loop() do
    infinite_loop()
  end
end
