# iex -S mix
#  StreamReader.start_link("http://localhost:4000/tweets/1")
defmodule Week2.StreamReader do
  use GenServer
  require Logger

  def start_link(url) do
    GenServer.start_link(__MODULE__, url: url)
  end

  def init(url: url) do
    Logger.info("Connecting to stream...")
    HTTPoison.get!(url, [], recv_timeout: :infinity, stream_to: self())
    {:ok, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, _state) do
    # process_event(chunk)
    case chunk do
      "event: \"message\"\n\ndata: {\"message\": panic}\n\n" ->
        Week2.LoadBalancer.print_tweets({:kill, "kill message"})

      "event: \"message\"\n\ndata: " <> message ->
        Week2.LoadBalancer.print_tweets(message)
    end

    {:noreply, nil}
  end

  # In addition to message chunks, we also may receive status changes etc.
  def handle_info(%HTTPoison.AsyncStatus{} = _, _state) do
    # IO.puts "Connection status: #{inspect status}"
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncHeaders{} = _, _state) do
    # IO.puts "Connection headers: #{inspect headers}"
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncEnd{} = _, _state) do
    # IO.puts "Connection headers: #{inspect headers}"
    {:noreply, nil}
  end

  # pattern match on string
  defp process_event("event: \"message\"\n\ndata: " <> message) do
    Week2.LoadBalancer.print_tweets(message)
  end

  defp process_event(_corrupted_event) do
    Week2.LoadBalancer.print_tweets({:kill, "kill message"})
  end
end
