defmodule Week6.GenericLoadBalancer do
  use GenServer
  require Logger

  @nr_of_workers 8
  @max_requests_per_node 1000
  @min_requests_per_node 50
  @min_workers 5
  @max_workers 7


  def start_link(arg) do
    GenServer.start_link(__MODULE__, {0, %{}, arg}, name: String.to_atom(arg.my_id))
  end

  # elem(state, 2) is a map formed from lb pid and printersuper pid
  def init(state) do
    Logger.info("GenericLoadBalancer is running...")

    nodeLoads =
      Enum.reduce(1..@nr_of_workers, %{}, fn _, acc -> Map.put(acc, UUID.uuid1(), 0) end)

    {:ok, {elem(state, 0), nodeLoads, elem(state, 2)}}
  end

  # called by reader
  # generic load balancer will choose a random load balancer of a random worker pool
  # type of load balancer should be an argument
  def send_work(type, chunk) do

    uuid = Week6.LBRegister.getRandomLBPid(type)

    GenServer.cast(String.to_atom(uuid), {:send_work, chunk})
  end

  def mark_job_finished(loadBalPid, uuid) do
    GenServer.cast(String.to_atom(loadBalPid), {:finished, uuid})
  end

  def handle_cast({:finished, uuid}, state) do
    nodeLoads = elem(state, 1)

    nodeLoads = Map.update(nodeLoads, uuid, 0, fn x -> x - 1 end)

    {:noreply, {elem(state, 0), nodeLoads, elem(state, 2)}}
  end

  def handle_cast({:send_work, chunk}, state) do
    infoMap = elem(state, 2)

    {workerID1, loadsMap} = getIDByLeastRequestLB(elem(state, 1), infoMap)

    Week6.GenericSupervisor.sendToWorkerX(
      infoMap.my_id,
      infoMap.printerSuperPid,
      workerID1,
      chunk,
      infoMap.moduleName
    )

    loadsMap =  case chunk do
      {:kill, "kill message"} ->
        loadsMap = Map.delete(loadsMap, workerID1)
        loadsMap
      _ ->
        loadsMap
    end


    {:noreply, {workerID1, loadsMap, elem(state, 2)}}
  end

  # Least Request Load Balancing
  def getIDByLeastRequestLB(nodeLoads, infoMap) do
    sum =
      Enum.reduce(nodeLoads, 0, fn {_, v}, sum ->
        sum + v
      end)

    averageRequests = sum / length(Map.keys(nodeLoads))

    # IO.puts("\n\n")
    # IO.puts("Current nr workers: #{length(Map.keys(nodeLoads))}")
    # IO.puts("\n\n")
    # IO.inspect(nodeLoads)
    # IO.puts("\n\n")
    # IO.puts(averageRequests)
    # IO.puts("\n\n")


    nodeLoads =
      if averageRequests < @min_requests_per_node and length(Map.keys(nodeLoads)) > @min_workers do
        uuid =
          nodeLoads
          |> Enum.min_by(fn {_, v} -> v end)
          |> elem(0)

        Week6.GenericSupervisor.sendToWorkerX(
          infoMap.my_id,
          infoMap.printerSuperPid,
          uuid,
          {:kill, "kill message"},
          infoMap.moduleName
        )

        nodeLoads = Map.delete(nodeLoads, uuid)
        nodeLoads
      else
        nodeLoads
      end

    uuid =
      if averageRequests > @max_requests_per_node and length(Map.keys(nodeLoads)) < @max_workers do
        UUID.uuid1()
      else
        nodeLoads
        |> Enum.min_by(fn {_, v} -> v end)
        |> elem(0)
      end

    nodeLoads = Map.update(nodeLoads, uuid, 1, fn x -> x + 1 end)

    {uuid, nodeLoads}
  end
end
