defmodule EngageCalculator do
  require Logger
  use GenServer

  def start_link do
    Logger.info("EngageCalculator #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(_state) do
    {:ok, %{}}
  end

  def calculate_engagement(pid, {favorites, retweets, followers}) do
    GenServer.call(pid, {:engageCalc, {favorites, retweets, followers}})
  end

  def handle_call({:engageCalc, {favorites, retweets, followers}}, _from, state) do
    if followers != 0 do
      engagement = (favorites + retweets) / followers

      # UserCache.set(name, engagement)

      {:reply, engagement, state}
    else

      {:reply, 0, state}
    end
  end

end
