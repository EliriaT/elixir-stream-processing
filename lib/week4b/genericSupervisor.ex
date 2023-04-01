defmodule Week4B.GenericSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: String.to_atom(arg.my_id))
  end

  # is the supervisor restarting with the same initial state,yes
  def init(_args) do
    Logger.info("GenericSupervisor is running...")
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 2_000_000, max_seconds: 5)
  end

  # moduleName is for example Week4b.Printer
  def start_new_child(moduleName, supervisorPid, uuid, loadBalPid) do
    # IF I DO NOT PUT ID, THE CHILD IS NOT STARTED, BUT IF I PUT ID, THE CHILD ID IS UNDEFINED
    DynamicSupervisor.start_child(
      String.to_atom(supervisorPid),
      %{id: uuid, start: {moduleName, :start_link, [{uuid, loadBalPid}]}}
    )
  end

  def sendToWorkerX(loadBalPid, printerSuperPid, uuid, chunk, moduleName) do
    # check if such  child with such uuid exists, if not, the child is created, initially load balancer creates 3 children

    children = Process.whereis(String.to_atom(uuid))

    if children == nil do
      Week4B.GenericSupervisor.start_new_child(moduleName, printerSuperPid, uuid, loadBalPid)
    end

    # all workers of the pool must implement this method
    moduleName.send_work(uuid, chunk)
  end
end
