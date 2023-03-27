defmodule Week3.Printer do
  use GenServer, restart: :transient
  require Logger

  @minSleepTime 5
  @maxSleepTime 50

  def start_link(uuid) do
    GenServer.start_link(__MODULE__, uuid, name: String.to_atom(uuid))
  end

  def init(id) do
    Logger.info("Printer #{inspect(id)} is running...")
    {:ok, id}
  end

  def print_tweet(uuid, chunk) do
    case chunk do
      {:kill, "kill message"} ->
        GenServer.cast(Process.whereis(String.to_atom(uuid)), {:kill, "kill message"})

      _ ->
        GenServer.cast(Process.whereis(String.to_atom(uuid)), {:print_tweet, chunk})
    end
  end

  def handle_cast({:kill, "kill message"}, uuid) do
    Week3.LoadBalancer.mark_job_finished(uuid)
    # messages = get_worker_messages(Process.whereis(String.to_atom(uuid)))

    # Enum.map(messages, fn m ->
    #   Week2.LoadBalancer.print_tweets(m)
    #   Week3.LoadBalancer.mark_job_finished(uuid)
    # end)

    exit(:kill)
    {:noreply, uuid}
  end

  def handle_cast({:print_tweet, chunk}, uuid) do
    sleep()
    {success, data} = Jason.decode(String.trim(chunk))

    if success == :ok do
      tweet = data["message"]["tweet"]
      text = tweet["text"]

      IO.puts("\n\n")
      # r = filter_bad_words(text)
      IO.puts(text)
      IO.puts("\n")
      hashtags = tweet["entities"]["hashtags"]
      Week3.StatMaker.send_hashtags(hashtags)

      # hash = :crypto.hash(:md5, text) |> Base.encode16()
      # Cache.get(hash)

      # case Cache.get(hash) do
      #   true ->
      #     Week3.LoadBalancer.mark_job_finished(uuid)
      #     {:noreply, uuid}
      #   false ->
      #     Cache.set(hash)
      #     IO.puts("\n\n")
      #     # r = filter_bad_words(text)
      #     IO.puts(text)
      #     IO.puts("\n")
      #     hashtags = tweet["entities"]["hashtags"]
      #     Week3.StatMaker.send_hashtags(hashtags)
      #     Week3.LoadBalancer.mark_job_finished(uuid)
      #     {:noreply, uuid}
      #   end
    end

    Week3.LoadBalancer.mark_job_finished(uuid)

    {:noreply, uuid}
  end

  defp sleep() do
    sleep_time = :rand.uniform(@maxSleepTime - @minSleepTime) + @minSleepTime
    :timer.sleep(sleep_time)
  end

  defp filter_bad_words(msg) do
    msg = URI.encode(msg)
    response = HTTPoison.get!("https://www.purgomalum.com/service/plain?text=#{msg}")
    Map.get(response, :body)
  end

  defp get_worker_messages(pid) do
    {:messages, messages} = Process.info(pid, :messages)
    Enum.map(messages, fn {_, msg} -> msg end)
  end
end
