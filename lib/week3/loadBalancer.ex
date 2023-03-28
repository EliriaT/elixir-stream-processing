defmodule Week3.LoadBalancer do
  use GenServer
  require Logger

  @nr_of_workers 3
  @max_requests_per_node 100
  @min_requests_per_node 50
  @min_workers 3

  def start_link() do
    GenServer.start_link(__MODULE__, {0, %{}}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("LoadBalancer is running...")

    nodeLoads =
      Enum.reduce(1..@nr_of_workers, %{}, fn _, acc -> Map.put(acc, UUID.uuid1(), 0) end)

    {:ok, {elem(state, 0), nodeLoads}}
  end

  def print_tweets(chunk) do
    GenServer.cast(__MODULE__, {:print_tweet, chunk})
  end

  def mark_job_finished(uuid) do
    GenServer.cast(__MODULE__, {:finished, uuid})
  end

  def handle_cast({:finished, uuid}, state) do
    nodeLoads = elem(state, 1)

    nodeLoads = Map.update(nodeLoads, uuid, 0, fn x -> x - 1 end)

    {:noreply, {elem(state, 0), nodeLoads}}
  end

  def handle_cast({:print_tweet, chunk}, state) do
    {workerID1, loadsMap} = getIDByLeastRequestLB(elem(state, 1))

    # {workerID2, loadsMap} = getIDByLeastRequestLB(loadsMap)


    Week3.PrinterSupervisor.sendToPrinterX(workerID1, chunk)
    # Week3.PrinterSupervisor.sendToPrinterX(workerID2, chunk)

    {:noreply, {workerID1, loadsMap}}
  end

  # Least Request Load Balancing
  def getIDByLeastRequestLB(nodeLoads) do
    sum =
      Enum.reduce(nodeLoads, 0, fn {_, v}, sum ->
        sum + v
      end)

    averageRequests = sum / length(Map.keys(nodeLoads))

    IO.puts("\n\n")
    IO.puts("Current nr workers: #{length(Map.keys(nodeLoads))}")
    IO.puts("\n\n")
    IO.inspect(nodeLoads)
    IO.puts("\n\n")
    IO.puts(averageRequests)
    IO.puts("\n\n")

    # ALWAYS PUT AN ELSE IN IF
    nodeLoads = if averageRequests < @min_requests_per_node and length(Map.keys(nodeLoads)) > @min_workers do

      uuid =
        nodeLoads
        |> Enum.min_by(fn {_, v} -> v end)
        |> elem(0)

      Week3.PrinterSupervisor.sendToPrinterX(uuid, {:kill, "kill message"})

      nodeLoads = Map.delete(nodeLoads,  uuid)
      nodeLoads
      else
        nodeLoads
    end

    uuid =
      if averageRequests > @max_requests_per_node do
        UUID.uuid1()
      else
        nodeLoads
        |> Enum.min_by(fn {_, v} -> v end)
        |> elem(0)
      end

    nodeLoads = Map.update(nodeLoads, uuid, 1, fn x -> x + 1 end)

    {uuid, nodeLoads}
  end

  # def getIDByRoundRobinLB(nextWorken) do
  #   rem(nextWorken, @nr_of_workers) + 1
  # end
end
