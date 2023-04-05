defmodule Week5.Printer do
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

    {:ok,
     %{
       id: id,
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
    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:kill)
    {:noreply, state}
  end

  def handle_cast({:print_tweet, chunk}, state) do
    sleep()

    tweet_id = UUID.uuid1()

    [{_, var_type} | _] = IEx.Info.info(chunk)

    {success, data} =
      if var_type == "BitString" do
        {success, data} = Jason.decode(String.trim(chunk))
        {success, data}
      else
        {:ok, chunk}
      end

    if success == :ok do
      tweet = data["message"]["tweet"]

      tweet =
        if tweet == nil do
          chunk
        else
          tweet
        end

      text = tweet["text"]

      favorites = tweet["favorite_count"]

      retweets = tweet["retweet_count"]

      followers = tweet["user"]["followers_count"]

      name = tweet["user"]["name"]

      hashtags = tweet["entities"]["hashtags"]

      # favorites =
      #   if favorites == nil do
      #     data["message"]["tweet"]["retweeted_status"]["favorite_count"]
      #   else
      #     favorites
      #   end

      # retweets = tweet["message"]["tweet"]["retweeted_status"]["retweet_count"]

      # retweets =
      #   if retweets == nil do
      #     tweet["retweet_count"]
      #   else
      #     retweets
      #   end

      SentAnalyser5.calculate_sentiment(tweet_id, text)

      EngageCalculator5.calculate_engagement(tweet_id, {favorites, retweets, followers, name})

      Redacter5.filter_bad_words(tweet_id, text)

      if hashtags != nil do
        Week5.StatMaker.send_hashtags(hashtags)
      end

      if Map.get(tweet, "retweeted_status", nil) != nil do
        send_work(state.id, tweet["retweeted_status"])
        # IO.puts("\n\n\n\n\n ESTE \n\n\n\n\n")
      end
    end

    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

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
