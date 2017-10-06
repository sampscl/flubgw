# FlubGw.TcpGateway.Supervisor.Supervisor
#

defmodule FlubGw.TcpGateway.Supervisor.Supervisor do
  use Supervisor

  #############
  # API
  #############

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    children = [
      supervisor(FlubGw.TcpRoute.Worker.Supervisor, []),
      supervisor(FlubGw.TcpGateway.Listener.Worker.Supervisor, []),
      supervisor(FlubGw.TcpGateway.Acceptor.Worker.Supervisor, []),
    ]
    supervise(children, strategy: :one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
