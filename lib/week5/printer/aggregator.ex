defmodule Week5.Aggregator do
  require Logger
  use GenServer

  def start_link() do
    Logger.info("Aggregator #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # state is %{ "uuid" : %{ engagement: 0, sentiment: 0, cleaned: ""}}

  def init(_) do
    {:ok, %{}}
  end

  def aggregate(message) do
    GenServer.cast(__MODULE__, {:agg, message})
  end

  def send_batch_size(size) do
    GenServer.cast(__MODULE__, {:size, size})
  end

  # this while loop will end either when batch size is accomplished or when there are no tweets aggregated
  def handle_cast({:size, batch_size}, state) do


    {_, state} =
      Enum.reduce_while(state, {0, state}, fn tuple, acc ->

        tweetId = elem(tuple, 0)
        aggregatedTweet = elem(tuple, 1)



        {counter, state_dict} =
          if length(Map.keys(aggregatedTweet)) == 3 do
            Week5.Batcher.send_to_batch(aggregatedTweet)
            counter = elem(acc, 0)
            state_dict = elem(acc, 1)

            {counter + 1, Map.delete(state_dict, tweetId)}
          else
            counter = elem(acc, 0)
            state_dict = elem(acc, 1)
            {counter, state_dict}
          end

        if counter == batch_size do
          {:halt, {counter, state_dict}}
        else
          {:cont, {counter, state_dict}}
        end
      end)

    {:noreply, state}
  end

  def handle_cast({:kill, "kill message"}, state) do
    exit(:kill)
    {:noreply, state}
  end

  def handle_cast({:agg, message}, state) do
    {_tweet_id, state} =
      case message do
        {:engagement, result} ->
          aggregatedTweet = Map.get(state, result.id, %{})
          aggregatedTweet = Map.put(aggregatedTweet, :engagement, result.score)

          {result.id, Map.put(state, result.id, aggregatedTweet)}

        {:cleaner, result} ->
          aggregatedTweet = Map.get(state, result.id, %{})
          aggregatedTweet = Map.put(aggregatedTweet, :cleaned, result.cleaned)

          {result.id, Map.put(state, result.id, aggregatedTweet)}

        {:sentiment, result} ->
          aggregatedTweet = Map.get(state, result.id, %{})
          aggregatedTweet = Map.put(aggregatedTweet, :sentiment, result.score)

          {result.id, Map.put(state, result.id, aggregatedTweet)}
      end

    # aggregated = Map.get(state, tweet_id, %{})

    # if length(Map.keys(aggregated)) == 3 do
    #   # Week5.Batcher.send_to_batch(aggregated)
    # end

    {:noreply, state}
  end
end
