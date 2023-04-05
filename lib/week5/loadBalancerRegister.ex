defmodule Week5.LBRegister do
  use GenServer

  def start_link do
    GenServer.start_link(
      __MODULE__,
      :ets.new(:loadBalancers, [:set, :public, :named_table]),
      name: __MODULE__
    )
  end

  # state is the reference of the ets table
  def init(ets_table) do
    {:ok, ets_table}
  end

  # type ex => :printer
  def addNewLoadBalancerType(type) do
    GenServer.cast(__MODULE__, {:addType, type})
  end

  def addNewLoadBalancer(type, lbPid) do
    GenServer.cast(__MODULE__, {:addLB, {type, lbPid}})
  end

  def getRandomLBPid(type) do
    GenServer.call(__MODULE__, {:getRandomPid, type})
  end

  def handle_cast({:addType, type}, ets_table) do
    :ets.insert(ets_table, {{:length, type}, 0})
    :ets.insert(ets_table, {type, []})

    {:noreply, ets_table}
  end

  def handle_cast({:addLB, {type, lbPid}}, ets_table) do
    [{_, listOfLB}] = :ets.lookup(ets_table, type)
    :ets.insert(ets_table, {type, [lbPid | listOfLB]})

    [{_, numberOfPools}] = :ets.lookup(ets_table, {:length, type})
    :ets.insert(ets_table, {{:length, type}, numberOfPools + 1})

    {:noreply, ets_table}
  end

  def handle_call({:getRandomPid, type}, _from, ets_table) do
    [{_, numberOfPools}] = :ets.lookup(:loadBalancers, {:length, type})

    loadBalIndex = :rand.uniform(numberOfPools)

    [{_, listOfLB}] = :ets.lookup(:loadBalancers, type)

    uuid = Enum.at(listOfLB, loadBalIndex - 1)

    {:reply, uuid, ets_table}
  end
end
