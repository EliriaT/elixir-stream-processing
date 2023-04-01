defmodule Week4B.StreamReader do
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
        Week4B.GenericLoadBalancer.send_work(:printer,{:kill, "kill message"})

      "event: \"message\"\n\ndata: " <> message ->
        Week4B.GenericLoadBalancer.send_work(:printer,message)

      "" -> Week4B.GenericLoadBalancer.send_work(:printer,"")

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

end
