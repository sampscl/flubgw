# FlubGw.HttpGateway.Worker
# addr, port

defmodule FlubGw.HttpGateway.Worker.Supervisor do
  use Supervisor

  #############
  # API
  #############

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def start_child(addr, port) do
    Supervisor.start_child(__MODULE__, [addr, port])
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    children = [
      worker(FlubGw.HttpGateway.Worker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
