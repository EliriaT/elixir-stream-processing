defmodule Week5.GenericPool do
  use Supervisor
  require Logger

  def start_link(worker_type) do
    Supervisor.start_link(__MODULE__, [worker_type], name: String.to_atom(UUID.uuid1()))
  end

  # LoadBalancer needs his uuid, and printersupervisor uuid
  # LB sends to printersupervisor his uuid and LB uuid
  # printersupervisor sends to printer LB uuid
  # ONLY LOAD BALANCER HAS TO KNOW ABOUT THE WORKER TYPE
  def init([worker_type]) do
    Logger.info("GenericPool is running...")

    loadBalPid = UUID.uuid1()
    genericSupervisorPid = UUID.uuid1()

    moduleName =
      case worker_type do
        :printer ->
          Week5.Printer

        :engage ->
          EngageCalculator5

        :sentiment ->
          SentAnalyser5

        :redacter ->
          Redacter5
      end

    children = [
      Supervisor.child_spec(
        {Week5.GenericLoadBalancer,
         %{
           my_id: loadBalPid,
           printerSuperPid: genericSupervisorPid,
           workerType: worker_type,
           moduleName: moduleName
         }},
        id: loadBalPid
      ),
      Supervisor.child_spec(
        {Week5.GenericSupervisor, %{my_id: genericSupervisorPid}},
        id: genericSupervisorPid
      )
    ]

    case worker_type do
      :printer ->
        Week5.LBRegister.addNewLoadBalancer(:printer, loadBalPid)

      :engage ->
        Week5.LBRegister.addNewLoadBalancer(:engage, loadBalPid)

      :sentiment ->
        Week5.LBRegister.addNewLoadBalancer(:sentiment, loadBalPid)

      :redacter ->
        Week5.LBRegister.addNewLoadBalancer(:redacter, loadBalPid)
    end

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 200, max_seconds: 5)
  end
end
