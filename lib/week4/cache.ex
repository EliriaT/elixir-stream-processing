defmodule Week4.Cache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ets.new(:cache, [:set, :public, :named_table]), name: __MODULE__)
  end

  def init(ets_table) do
    {:ok, ets_table}
  end

  @spec get(any) :: true | false
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def set(key) do
    GenServer.cast(__MODULE__, {:set, key})
  end

  def handle_call({:get, key}, _from, ets_table) do
    case :ets.lookup(ets_table, key) do
      [{^key, _}] -> {:reply, true, ets_table}
      [] -> {:reply, false, ets_table}
    end
  end

  def handle_cast({:set, key}, ets_table) do
    :ets.insert(ets_table, {key, true})
    {:noreply, ets_table}
  end
end
