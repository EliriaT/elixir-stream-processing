defmodule Week1.Printer do
  use GenServer
  require Logger

  @minSleepTime 5
  @maxSleepTime 50

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Week1.Printer)
  end

  def init(state) do
    Logger.info("Printer is running...")
    {:ok, state}
  end

  def print_tweet(chunk) do
    GenServer.cast(Week1.Printer, {:print_tweet, chunk})
  end

  def handle_cast({:print_tweet, chunk}, state) do
    sleep()
    {success, data} = Jason.decode(String.trim(chunk))

    if success == :ok do
      tweet = data["message"]["tweet"]
      text = tweet["text"]
      IO.puts("\n\n")
      IO.puts(text)
      IO.puts("\n")

      hashtags = tweet["entities"]["hashtags"]
      Week1.StatMaker.send_hashtags(hashtags)
    end

    {:noreply, state}
  end

  defp sleep() do
    sleep_time = :rand.uniform(@maxSleepTime - @minSleepTime) + @minSleepTime
    :timer.sleep(sleep_time)
  end
end
