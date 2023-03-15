# iex -S mix
#  StreamReader.start_link("http://localhost:4000/tweets/1")
defmodule Week1.StreamReader do
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
    process_event(chunk)
    # :timer.sleep(1000);
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

  # pattern match on string
  defp process_event("event: \"message\"\n\ndata: " <> message) do
    Week1.Printer.print_tweet(message)
   
  end

  defp process_event(_corrupted_event) do
    exit(:hi)
  end
end
