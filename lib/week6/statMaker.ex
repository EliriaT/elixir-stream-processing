defmodule Week6.StatMaker do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    Logger.info("StatMakers is running...")
    schedule_work()
    {:ok, state}
  end

  defp schedule_work do
    Process.send_after(__MODULE__, :work, 5000)
  end

  def send_hashtags(hashtags) do
    GenServer.cast(__MODULE__, {:receive_hashtags, hashtags})
  end

  def handle_cast({:receive_hashtags, hashtags}, state) do
    hashtags = Enum.map(hashtags, fn x -> x["text"] end)
    state = state ++ hashtags

    {:noreply, state}
  end

  def handle_info(:work, state) do
    state = do_recurrent_thing(state)
    schedule_work()
    {:noreply, state}
  end

  defp do_recurrent_thing(state) do
    if length(state) != 0 do
      stats = Enum.frequencies(state)
      stats = Enum.map(stats, fn {key, value} -> {key, value} end)
      max = Enum.max_by(stats, fn x -> elem(x, 1) end)

      IO.puts(
        "============^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^============\n\n\n\n\n\n\n\n\n\t\tA popular hashtag is:  #{elem(max, 0)}\n\n\n\n\n\n\n\n\n============^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^============"
      )
    end

    []
  end
end
