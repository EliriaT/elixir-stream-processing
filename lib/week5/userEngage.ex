
defmodule UserCache5 do
  use GenServer

  @time 5000

  def start_link do
    GenServer.start_link(__MODULE__, :ets.new(:usercache, [:set, :public]), name: __MODULE__)
  end

  def init(ets_table) do
    schedule_work()
    {:ok, ets_table}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @time)
  end

  def set(key, value) do
    GenServer.cast(__MODULE__, {:set, key, value})
  end

  def handle_cast({:set, key, value}, ets_table) do
    case :ets.lookup(ets_table, key) do
      [] -> :ets.insert(ets_table, {key, value})
      [{^key, old_value}] -> :ets.insert(ets_table, {key, old_value + value})
    end
    {:noreply, ets_table}
  end

  def handle_info(:work, ets_table) do
    schedule_work()

    # Get all key-value pairs and sort by value
    items = :ets.tab2list(ets_table)
    sorted_items = Enum.sort_by(items, fn {_, value} -> value end, &>=/2)

    # Print the top 5 users by value
    top_items_string =
      Enum.reduce(Enum.take(sorted_items, 5), "", fn {key, value}, acc ->
        acc <> "#{key}: #{value}\n"
      end)

    IO.puts("\n\n\n\n\n\n\n\n\## Top 5 users by engagement:\n#{top_items_string}\n\n\n\n\n\n\n\n")

    {:noreply, ets_table}
  end

end
