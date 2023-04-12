defmodule Week6.GenericPool do
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
          Week6.Printer

        :engage ->
          EngageCalculator6

        :sentiment ->
          SentAnalyser6

        :redacter ->
          Redacter6
      end

    children = [
      Supervisor.child_spec(
        {Week6.GenericLoadBalancer,
         %{
           my_id: loadBalPid,
           printerSuperPid: genericSupervisorPid,
           workerType: worker_type,
           moduleName: moduleName
         }},
        id: loadBalPid
      ),
      Supervisor.child_spec(
        {Week6.GenericSupervisor, %{my_id: genericSupervisorPid}},
        id: genericSupervisorPid
      )
    ]

    case worker_type do
      :printer ->
        Week6.LBRegister.addNewLoadBalancer(:printer, loadBalPid)

      :engage ->
        Week6.LBRegister.addNewLoadBalancer(:engage, loadBalPid)

      :sentiment ->
        Week6.LBRegister.addNewLoadBalancer(:sentiment, loadBalPid)

      :redacter ->
        Week6.LBRegister.addNewLoadBalancer(:redacter, loadBalPid)
    end

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 200, max_seconds: 5)
  end
end
