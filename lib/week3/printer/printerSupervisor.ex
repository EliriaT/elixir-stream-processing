defmodule Week3.PrinterSupervisor do
  use DynamicSupervisor
  require Logger

  @nr_of_workers 3

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # is the supervisor restarting with the same initial state,yes
  def init(_args) do
    Logger.info("PrinterSupervisor is running...")
    DynamicSupervisor.init([strategy: :one_for_one, max_restarts: 2000000, max_seconds: 5])
  end

  def start_new_child(uuid) do

    # THIS IS SO STUPID, IF I DO NOT PUT ID, THE CHILD IS NOT STARTED, BUT IF I PUT ID, THE CHILD ID IS UNDEFINED
      DynamicSupervisor.start_child(
        __MODULE__,
        %{id: uuid, start: {Week3.Printer, :start_link, [uuid]}}
      )

  end

  def sendToPrinterX(uuid, chunk)  do
    # check if such  child with such uuid exists, if not, the child is created, initially load balancer creates 3 children

    # children =
    #   Supervisor.which_children(__MODULE__)
    #   |> Enum.find(fn {id, _, _, _} -> id == uuid end)

    # IO.inspect( Supervisor.which_children(__MODULE__))
    # IO.inspect(children)

    children =  Process.whereis(String.to_atom(uuid))

    if children==nil do
      Week3.PrinterSupervisor.start_new_child(uuid)
    end

    Week3.Printer.print_tweet(uuid, chunk)
  end
end
