defmodule Week4.GenericPool do
  use Supervisor
  require Logger

  def start_link(counter) do
    Supervisor.start_link(__MODULE__, [counter], name: String.to_atom(UUID.uuid1()) )
  end

  # LoadBalancer needs his uuid, and printersupervisor uuid
  # LB sends to printersupervisor his uuid and LB uuid
  # printersupervisor sends to printer LB uuid
  def init([counter]) do
    Logger.info("GenericPool is running...")

    loadBalPid = UUID.uuid1()
    printerSupervisorPid = UUID.uuid1()

    children = [
      Supervisor.child_spec(
        {Week4.LoadBalancer, %{my_id: loadBalPid, printerSuperPid: printerSupervisorPid}},
        id: loadBalPid
      ),
      Supervisor.child_spec(
        {Week4.PrinterSupervisor, %{my_id: printerSupervisorPid}},
        id: printerSupervisorPid
      )
    ]


    :ets.insert(:loadBal,{counter,loadBalPid})

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 20000, max_seconds: 5)
  end

end
