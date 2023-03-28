defmodule SentAnalyser do
  require Logger
  use GenServer

  def start_link do
    Logger.info("SentAnalyser #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(_state) do

    text = HTTPoison.get!("localhost:4000/emotion_values")
    |> Map.get(:body)

    state = parse(text)

    {:ok, state}
  end

  def calculate_sentiment(pid, tweet) do
    GenServer.call(pid, {:calculateSent , tweet})
  end

  def handle_call({:calculateSent , tweet}, _from, state) do

    words = String.downcase(tweet) |> String.trim() |> String.split(~r/\s+/)

   total_score = Enum.reduce(words, 0, fn word, acc ->
      case Map.get(state, word) do
        nil -> acc
        score -> acc + score
      end
    end)

    mean_score = total_score / Enum.count(words)


    {:reply, mean_score, state}
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
