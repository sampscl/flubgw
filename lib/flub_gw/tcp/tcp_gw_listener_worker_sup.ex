# FlubGw.TcpGateway.Listener.Worker
# addr, port

defmodule FlubGw.TcpGateway.Listener.Worker.Supervisor do
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
      worker(FlubGw.TcpGateway.Listener.Worker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
