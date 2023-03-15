defmodule Week2.PrinterSupervisor do
  use Supervisor
  require Logger

  @nr_of_workers 3

  def start_link do
    pid =
      Supervisor.start_link(__MODULE__, nr_of_workers: @nr_of_workers, name: __MODULE__)
    |> elem(1)
    Process.register(pid, __MODULE__)
  end

  # is the supervisor restarting with the same initial state?
  def init(args) do
    Logger.info("PrinterSupervisor is running...")

    # i is the initial state
    children =
      Enum.map(1..args[:nr_of_workers], fn i ->
        %{
          id: i,
          start: {Week2.Printer, :start_link, [i]}
        }
      end)

    Supervisor.init(children, [strategy: :one_for_one, max_restarts: 10, max_seconds: 2]) #:max_seconds
  end

  def sendToPrinterX(id,chunk) when is_integer(id) do
    children = Supervisor.which_children(__MODULE__)
    |> Enum.find(fn {i, _, _, _} -> i == id end)
    |> elem(1)

    Week2.Printer.print_tweet(children,chunk)

  end

end
