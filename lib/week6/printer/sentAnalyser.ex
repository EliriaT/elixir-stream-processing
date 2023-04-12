defmodule SentAnalyser6 do
  require Logger
  use GenServer

  def start_link({id, loadBalPid}) do
    Logger.info("SentAnalyser #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, {id, loadBalPid}, name: String.to_atom(id))
  end

  def init(state) do
    text =
      HTTPoison.get!("localhost:4000/emotion_values")
      |> Map.get(:body)

    emotion_dict = parse(text)

    {:ok, %{id: elem(state,0), loadBalPid: elem(state,1), emotionDict: emotion_dict}}
  end

  def calculate_sentiment(tweet_id,tweet) do
    Week6.GenericLoadBalancer.send_work(:sentiment, {:calculateSent,tweet_id, tweet})

  end

  def send_work(uuid,work) do
    GenServer.cast(Process.whereis(String.to_atom(uuid)), work)
  end

  def handle_cast({:kill, "kill message"}, state) do
    Week6.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:normal)
    {:noreply, state}
  end

  def handle_cast({:calculateSent,tweet_id, tweet}, state) do
    words = String.downcase(tweet) |> String.trim() |> String.split(~r/\s+/)

    total_score =
      Enum.reduce(words, 0, fn word, acc ->
        case Map.get(state.emotionDict, word) do
          nil -> acc
          score -> acc + score
        end
      end)

    mean_score = total_score / Enum.count(words)

    # IO.puts(
    #   "\n\n" <>
    #     "Sentiment score:  #{mean_score} \n"
    # )

    Week6.Aggregator.aggregate({:sentiment, %{id: tweet_id, score: mean_score}})

    Week6.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    {:noreply, state}
  end

  defp parse(text) do
    text
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      words = String.split(line, ~r/\s+/, trim: true)
      value = String.to_integer(List.last(words))
      key = Enum.join(List.delete_at(words, -1), " ")
      Map.put(acc, key, value)
    end)
  end
end
