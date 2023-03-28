
defmodule Redacter do
  require Logger
  use GenServer

  def start_link do
    Logger.info("Redacter #{inspect(self())} is running...")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(_state) do
    config = Expletive.configure(blacklist: Expletive.Blacklist.english)
    {:ok,config}
  end

  def filter_bad_words(pid, msg) do
    GenServer.call(pid, {msg})
  end

  def handle_call({msg}, _from, config) do
    clean_msg =  Expletive.sanitize(msg, config)

    {:reply, clean_msg, config}
  end
end
