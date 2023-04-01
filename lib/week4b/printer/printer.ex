defmodule Week4B.Printer do
  use GenServer, restart: :transient
  require Logger

  @minSleepTime 5
  @maxSleepTime 50

  def start_link({id, loadBalPid}) do
    GenServer.start_link(__MODULE__, {id, loadBalPid}, name: String.to_atom(id))
  end

  # Printer must have pids of each worker pool load balancer
  def init({id, loadBalPid}) do
    Logger.info("Printer #{inspect(id)} is running...")

    # {:ok, sentimentPid} = SentAnalyserB.start_link()
    # {:ok, engagementPid} = EngageCalculatorB.start_link()
    # {:ok, redacterPid} = RedacterB.start_link()

    {:ok,
     %{
       id: id,
       #  sentPid: sentimentPid,
       #  engagePid: engagementPid,
       #  redacterPid: redacterPid,
       loadBalPid: loadBalPid
     }}
  end

  def send_work(id, chunk) do
    case chunk do
      {:kill, "kill message"} ->
        GenServer.cast(Process.whereis(String.to_atom(id)), {:kill, "kill message"})

      _ ->
        GenServer.cast(Process.whereis(String.to_atom(id)), {:print_tweet, chunk})
    end
  end

  def handle_cast({:kill, "kill message"}, state) do
    Week4B.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:kill)
    {:noreply, state}
  end

  def handle_cast({:print_tweet, chunk}, state) do
    sleep()
    {success, data} = Jason.decode(String.trim(chunk))

    if success == :ok do
      # IO.inspect(data)
      tweet = data["message"]["tweet"]
      text = tweet["text"]

      favorites = data["message"]["tweet"]["retweeted_status"]["favorite_count"]

      favorites =
        if favorites == nil do
          tweet["favorite_count"]
        else
          favorites
        end

      retweets = tweet["message"]["tweet"]["retweeted_status"]["retweet_count"]

      retweets =
        if retweets == nil do
          tweet["retweet_count"]
        else
          retweets
        end

      followers = tweet["user"]["followers_count"]
      name = tweet["user"]["name"]
      hashtags = tweet["entities"]["hashtags"]

      SentAnalyserB.calculate_sentiment(text)

      EngageCalculatorB.calculate_engagement({favorites, retweets, followers, name})

      RedacterB.filter_bad_words(text)

      # IO.puts(
      #   "\n\n" <>
      #     # "Sentiment score:  #{sent_score} \n" <>
      #     # "Engagement score: #{engage_score} \n" <>
      #     redacted_tweet <> "\n"
      # )

      Week4B.StatMaker.send_hashtags(hashtags)
    end

    Week4B.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    {:noreply, state}
  end

  defp sleep() do
    sleep_time = :rand.uniform(@maxSleepTime - @minSleepTime) + @minSleepTime
    :timer.sleep(sleep_time)
  end

  defp get_worker_messages(pid) do
    {:messages, messages} = Process.info(pid, :messages)
    Enum.map(messages, fn {_, msg} -> msg end)
  end
end
