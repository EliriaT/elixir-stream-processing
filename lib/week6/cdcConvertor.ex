defmodule Week6.CDCConverter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    {:ok, socket} =
      :gen_tcp.connect({127, 0, 0, 1}, 4041, [:binary, packet: :line, active: false])

    {:ok, socket}
  end

  def publishTweet(tweetID, engagement, sentiment, cleaned, userID) do
    GenServer.cast(__MODULE__, {:publishTweet, tweetID, engagement, sentiment, cleaned, userID})
  end

  def handle_cast({:publishTweet, tweetID, engagement, sentiment, cleaned, userID}, socket) do
    jsonToSend = %{
      id: tweetID,
      engagement: engagement,
      sentiment: sentiment,
      cleaned: cleaned,
      userID: userID
    }

    {:ok, jsonToSend} = Jason.encode(jsonToSend)


    msg_to_send = "{ \"type\": \"PUB\", \"topic\": \"tweets\", \"msg\": #{inspect(jsonToSend)} }"
    :gen_tcp.send(socket, msg_to_send <> "\r\n")

    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data =
          case Jason.decode(data) do
            {:ok, map} ->
              map

            {:error, error} ->
              error
          end

        case data do
          %{"type" => "PUBREC", "msgId" => messageId} ->
            msg_to_send = "{ \"type\": \"PUBREL\", \"msgId\": #{messageId} }"
            :gen_tcp.send(socket, msg_to_send <> "\r\n")

          _ ->
            ""
        end

      {:error, _} = err ->
        ""
    end

    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data =
          case Jason.decode(data) do
            {:ok, map} ->
              map

            {:error, error} ->
              error
          end

        case data do
          %{"type" => "PUBCOMP", "msgId" => messageId} ->
            # i can delete the message or not send it anymore
            ""

          _ ->
            ""
        end

      {:error, _} ->
        ""
    end

    {:noreply, socket}
  end
end
