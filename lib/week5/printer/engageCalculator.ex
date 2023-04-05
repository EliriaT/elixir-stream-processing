defmodule EngageCalculator5 do
  require Logger
  use GenServer

  def start_link({id, loadBalPid}) do
    Logger.info("EngageCalculator #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, {id, loadBalPid}, name: String.to_atom(id))
  end

  def init({id, loadBalPid}) do
    {:ok, %{id: id, loadBalPid: loadBalPid}}
  end

  def calculate_engagement(tweet_id, {favorites, retweets, followers, name}) do
    Week5.GenericLoadBalancer.send_work(
      :engage,
      {:engageCalc, {tweet_id, favorites, retweets, followers, name}}
    )

    # GenServer.call(pid, {:engageCalc, {favorites, retweets, followers}})
  end

  def send_work(uuid, work) do
    GenServer.cast(Process.whereis(String.to_atom(uuid)), work)
  end

  def handle_cast({:engageCalc, {tweet_id, favorites, retweets, followers, name}}, state) do
    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    if followers != 0 do
      engagement = (favorites + retweets) / followers

      # IO.puts(
      #   "\n\n" <>
      #     "Engagement score:  #{engagement} \n"
      # )
      Week5.Aggregator.aggregate({:engagement, %{id: tweet_id, score: engagement}})

      UserCache5.set(name, engagement)
      {:noreply, state}
    else
      # IO.puts(
      #   "\n\n" <>
      #     "Engagement score:  0 \n"
      # )

      Week5.Aggregator.aggregate({:engagement, %{id: tweet_id, score: 0}})

      UserCache5.set(name, 0)
      {:noreply, state}
    end
  end

  def handle_cast({:kill, "kill message"}, state) do
    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:kill)
    {:noreply, state}
  end
end
