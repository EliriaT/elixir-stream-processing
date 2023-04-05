defmodule Redacter5 do
  require Logger
  use GenServer

  def start_link({id, loadBalPid}) do
    Logger.info("Redacter #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, {id, loadBalPid}, name: String.to_atom(id))
  end

  def init(state) do
    config = Expletive.configure(blacklist: Expletive.Blacklist.english())

    {:ok, %{id: elem(state, 0), loadBalPid: elem(state, 1), config: config}}
  end

  def filter_bad_words(tweet_id, msg) do
    Week5.GenericLoadBalancer.send_work(:redacter, {tweet_id,  msg})
    # GenServer.call(pid, {msg})
  end

  def send_work(uuid, work) do
    GenServer.cast(Process.whereis(String.to_atom(uuid)), work)
  end

  def handle_cast({:kill, "kill message"}, state) do
    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    exit(:kill)
    {:noreply, state}
  end

  def handle_cast({tweet_id,  msg}, state) do

    clean_msg = Expletive.sanitize(msg, state.config)

    Week5.Aggregator.aggregate({:cleaner, %{id: tweet_id, cleaned: clean_msg}})

    # Week5.Batcher.send_to_batch(clean_msg)
    # IO.puts(
    #   "\n\n" <>
    #     "Cleaned tweet:  #{clean_msg} \n"
    # )

    Week5.GenericLoadBalancer.mark_job_finished(state.loadBalPid, state.id)

    {:noreply,  state}
  end
end
