defmodule Week6.TweetDb do
  use GenServer

  @time 5000
  # tweetID engagement sentiment redacted UserID
  # userID userName

  def start_link do
    GenServer.start_link(__MODULE__, :ets.new(:tweetDb, [:set, :public]), name: __MODULE__)
  end

  def init(ets_table) do
    schedule_work()
    {:ok, ets_table}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @time)
  end

  def setTweet(tweetID, engagement, sentiment, cleaned, userID) do
    GenServer.cast(__MODULE__, {:setTweet, tweetID, engagement, sentiment, cleaned, userID})
  end

  def setUser(userID, name) do
    GenServer.cast(__MODULE__, {:setUser, userID, name})
  end

  def handle_cast({:setTweet, tweetID, engagement, sentiment, cleaned, userID}, ets_table) do
    tweetList =
      case :ets.lookup(ets_table, :tweets) do
        [] -> []
        [{_key, old_list}] -> old_list
      end

    :ets.insert(
      ets_table,
      {:tweets,
       [
         %{
           id: tweetID,
           engagement: engagement,
           sentiment: sentiment,
           redacted: cleaned,
           userID: userID
         }
         | tweetList
       ]}
    )

    {:noreply, ets_table}
  end

  def handle_cast({:setUser, userID, name}, ets_table) do
    userList =
      case :ets.lookup(ets_table, :users) do
        [] -> []
        [{_key, old_list}] -> old_list
      end

    :ets.insert(
      ets_table,
      {:users,
       [
         %{id: userID, name: name}
         | userList
       ]}
    )

    {:noreply, ets_table}
  end

  def handle_info(:work, ets_table) do
    schedule_work()

    # Get all key-value pairs and sort by value
    items = :ets.tab2list(ets_table)

    IO.puts("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\## Current Database:\n#{inspect(items)}\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")

    {:noreply, ets_table}
  end
end
