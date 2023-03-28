defmodule Week4.PrinterSupervisor do
  use DynamicSupervisor
  require Logger

  @nr_of_workers 3

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: String.to_atom(arg.my_id))
  end

  # is the supervisor restarting with the same initial state,yes
  def init(_args) do
    Logger.info("PrinterSupervisor is running...")
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 2_000_000, max_seconds: 5)
  end

  def start_new_child(printerSuperPid, uuid,loadBalPid) do
    # THIS IS SO STUPID, IF I DO NOT PUT ID, THE CHILD IS NOT STARTED, BUT IF I PUT ID, THE CHILD ID IS UNDEFINED
    DynamicSupervisor.start_child(
      String.to_atom(printerSuperPid),
      %{id: uuid, start: {Week4.Printer, :start_link, [{uuid,loadBalPid}]}}
    )
  end

  def sendToPrinterX(loadBalPid, printerSuperPid, uuid, chunk) do
    # check if such  child with such uuid exists, if not, the child is created, initially load balancer creates 3 children

    children = Process.whereis(String.to_atom(uuid))

    if children == nil do
      Week4.PrinterSupervisor.start_new_child(printerSuperPid, uuid,loadBalPid)
    end

    Week4.Printer.print_tweet(uuid, chunk)
  end
end
