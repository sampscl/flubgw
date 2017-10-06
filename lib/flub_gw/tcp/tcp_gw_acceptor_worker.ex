# socket
# FlubGw.TcpGateway.Acceptor.Worker

defmodule FlubGw.TcpGateway.Acceptor.Worker do
  use GenServer

  ##############################
  # API
  ##############################

  def start_link(socket) do
    GenServer.start_link(__MODULE__, [socket])
  end

  defmodule State do
    @doc false
    defstruct [
      socket: nil, # my socket
      accept_pid: nil, # pid that actually does the accepting
    ]
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([socket]) do
    accept_pid = spawn_link(fn() -> do_accept_loop(socket) end)
    {:ok, %State{socket: socket, accept_pid: accept_pid}}
  end

  ##############################
  # Internal Calls
  ##############################

  def do_accept_loop(socket) do
    {:ok, accepted_sock} = :gen_tcp.accept(socket)
    {:ok, new_owner_pid} = FlubGw.TcpRoute.Worker.Supervisor.start_child(accepted_sock)
    :ok = :gen_tcp.controlling_process(accepted_sock, new_owner_pid)
    FlubGw.TcpRoute.Worker.take_ownership(new_owner_pid)
    do_accept_loop(socket)
  end

end
