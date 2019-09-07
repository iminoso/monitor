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
  Calculates memory of the system returning a keyword list of the form in MB:
  eg. [total_memory: _, free_memory: _, system_total_memory: _]
  """
  def system_memory_data() do
    :memsup.get_system_memory_data
    |> Keyword.new(fn {k,v} -> {k, (v / 1000000) |> Kernel.trunc()} end)
  end
end
