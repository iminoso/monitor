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

  # Calculates memory of the system returning a keyword list of the form in MB:
  # eg. [total_memory: _, free_memory: _, system_total_memory: _]
  def system_memory_data() do
    :memsup.get_system_memory_data
    |> Keyword.new(fn {k,v} -> {k, (v / 1000000) |> Kernel.trunc()} end)
  end
end
