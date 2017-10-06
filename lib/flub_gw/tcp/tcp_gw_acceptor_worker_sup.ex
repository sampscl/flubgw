# FlubGw.TcpGateway.Acceptor.Worker
# socket

defmodule FlubGw.TcpGateway.Acceptor.Worker.Supervisor do
  use Supervisor

  #############
  # API
  #############

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def start_child(socket) do
    Supervisor.start_child(__MODULE__, [socket])
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    children = [
      worker(FlubGw.TcpGateway.Acceptor.Worker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
