defmodule Week6.Batcher do
  require Logger
  use GenServer

  @batch_size 10
  @time_window 5000

  def start_link() do
    Logger.info("Batcher #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{counter: 0, messages: [], previousTime: Time.utc_now()}}
  end

  def schedule_work do
    Process.send_after(__MODULE__, :check_time, @time_window)
  end

  def ask_for_messages() do
    Week6.Aggregator.send_batch_size(@batch_size)
  end

  def send_to_batch(aggregated_tweet) do
    GenServer.cast(__MODULE__, {:batch, aggregated_tweet})
  end

  def handle_info(:check_time, state) do
    state =
      if Time.diff(Time.utc_now(), state.previousTime, :millisecond) >= @time_window do
        IO.puts("\n\n\n\n\n\n\n\n TIMP EXPIRAT\n\n\n\n\n\n\n\n\n")
        print_batch(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:batch, aggregated_tweet}, state) do
    state = Map.put(state, :counter, state.counter + 1)

    state = Map.put(state, :messages, [aggregated_tweet | state.messages])

    state =
      if state.counter == @batch_size do
        print_batch(state)
      else
        state
      end

    {:noreply, state}
  end

  def print_batch(state) do


    state = if Process.alive?(Process.whereis(__MODULE__)) do
      IO.puts(
        "\n\n----------------------------------------------------------------------------------------------------\n\n"
      )

      Enum.each(state.messages, fn m ->
        # IO.puts(
        #   "\n Engagement: #{m.engagement} \n Sentiment: #{m.sentiment} \n Cleaned_string: #{m.cleaned} \n User ID: #{m.userID} \n User Name: #{m.userName}"
        # )

        Week6.TweetDb.setTweet(m.tweetID, m.engagement, m.sentiment, m.cleaned, m.userID)
        Week6.TweetDb.setUser( m.userID, m.userName)
      end)

      IO.puts(
        "\n\n----------------------------------------------------------------------------------------------------\n\n"
      )

    schedule_work()
    ask_for_messages()

    state = Map.put(state, :counter, 0)
    state = Map.put(state, :messages, [])
    state = Map.put(state, :previousTime, Time.utc_now())
    state
    else
      :timer.sleep(100)
      print_batch(state)
    end

    state
  end
end
