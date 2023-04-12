defmodule EngageCalculator6 do
  require Logger
  use GenServer

  def start_link({id, loadBalPid}) do
    Logger.info("EngageCalculator #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, {id, loadBalPid}, name: String.to_atom(id))
  end

  def init({id, loadBalPid}) do
    {:ok, %{id: id, loadBalPid: loadBalPid}}
  end

  def calculate_engagement(tweet_id, {favorites, retweets, followers, name, userID}) do
    Week6.GenericLoadBalancer.send_work(
      :engage,
      {:engageCalc, {tweet_id, favorites, retweets, followers, name, userID}}
    )

    # GenServer.call(pid, {:engageCalc, {favorites, retweets, followers}})
  end

  def send_work(uuid, work) do
    GenServer.cast(Process.whereis(String.to_atom(uuid)), work)
  end

  def handle_cast({:engageCalc, {tweet_id, favorites, retweets, followers, name, userID}}, state) do
    Week6.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    if followers != 0 do
      engagement = (favorites + retweets) / followers

      # IO.puts(
      #   "\n\n" <>
      #     "Engagement score:  #{engagement} \n"
      # )
      Week6.Aggregator.aggregate({:engagement, %{id: tweet_id, score: engagement, name: name, userID: userID}})

      UserCache6.set(name, engagement)
      {:noreply, state}
    else
      # IO.puts(
      #   "\n\n" <>
      #     "Engagement score:  0 \n"
      # )

      Week6.Aggregator.aggregate({:engagement, %{id: tweet_id, score: 0, name: name, userID: userID}})

      UserCache6.set(name, 0)
      {:noreply, state}
    end
  end

  def handle_cast({:kill, "kill message"}, state) do
    Week6.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:kill)
    {:noreply, state}
  end
end
