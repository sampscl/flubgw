# FlubGw.TcpRoute.Worker
# route_or_socket

defmodule FlubGw.TcpRoute.Worker.Supervisor do
  use Supervisor

  #############
  # API
  #############

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def start_child(route_or_socket) do
    Supervisor.start_child(__MODULE__, [route_or_socket])
  end

  def stop_child(route_or_socket) do
    FlubGw.TcpRoute.Worker.stop(route_or_socket)
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    children = [
      worker(FlubGw.TcpRoute.Worker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
