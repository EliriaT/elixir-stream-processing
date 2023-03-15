defmodule Week2.Printer do
  use GenServer
  require Logger

  @minSleepTime 5
  @maxSleepTime 50

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def init(id) do
    Logger.info("Printer is running...")
    {:ok, id}
  end

  def print_tweet(pid, chunk) do
    case chunk do
      {:kill, "kill message"} ->
        GenServer.cast(pid, {:kill, "kill message"})

      _ ->
        GenServer.cast(pid, {:print_tweet, chunk})
    end
  end

  def handle_cast({:kill, "kill message"}, id) do
    Week2.LoadBalancer.mark_job_finished(id)
    exit(:kill)
    {:noreply, id}
  end

  def handle_cast({:print_tweet, chunk}, id) do
    sleep()
    {success, data} = Jason.decode(String.trim(chunk))

    if success == :ok do
      tweet = data["message"]["tweet"]
      text = tweet["text"]
      IO.puts("\n\n")
      IO.puts(text)
      IO.puts("\n")

      hashtags = tweet["entities"]["hashtags"]
      Week2.StatMaker.send_hashtags(hashtags)
    end

    Week2.LoadBalancer.mark_job_finished(id)
    {:noreply, id}
  end

  defp sleep() do
    sleep_time = :rand.uniform(@maxSleepTime - @minSleepTime) + @minSleepTime
    :timer.sleep(sleep_time)
  end
end
