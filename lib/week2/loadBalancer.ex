defmodule Week2.LoadBalancer do
  use GenServer
  require Logger

  @nr_of_workers 3

  def start_link() do
    GenServer.start_link(__MODULE__, {0, %{}}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("LoadBalancer is running...")
    nodeLoads = Enum.reduce(1..@nr_of_workers, %{}, fn i, acc -> Map.put(acc, i, 0) end)

    {:ok, {elem(state, 0), nodeLoads}}
  end

  def print_tweets(chunk) do
    GenServer.cast(__MODULE__, {:print_tweet, chunk})
  end

  def mark_job_finished(id) do
    GenServer.cast(__MODULE__, {:finished, id})
  end

  def handle_cast({:finished, id}, state) do
    nodeLoads = elem(state, 1)
    nodeLoads = Map.update(nodeLoads, id, 0, fn x -> x - 1 end)

    {:noreply, {elem(state, 0), nodeLoads}}
  end

  def handle_cast({:print_tweet, chunk}, state) do
    # nrWorker = elem(state, 0)
    # workerID = getIDByRoundRobinLB(nrWorker)

    {workerID, loadsMap} = getIDByLeastRequestLB(elem(state, 1))
  

    Week2.PrinterSupervisor.sendToPrinterX(workerID, chunk)

    {:noreply, {workerID, loadsMap}}
  end

  def getIDByRoundRobinLB(nextWorken) do
    rem(nextWorken, @nr_of_workers) + 1
  end

  # Least Request Load Balancing
  def getIDByLeastRequestLB(nodeLoads) do
    id =
      nodeLoads
      |> Enum.min_by(fn {_, v} -> v end)
      |> elem(0)

    nodeLoads = Map.update(nodeLoads, id, 1, fn x -> x + 1 end)
    {id, nodeLoads}
  end
end
