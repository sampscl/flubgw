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
    {accept_pid, _ref} = spawn_monitor(fn() -> do_accept_loop(self(), socket) end)
    {:ok, %State{socket: socket, accept_pid: accept_pid}}
  end

  def handle_info({:DOWN, _ref, :process, _object, reason}, state) do
    {:stop, reason, state}
  end

  ##############################
  # Internal Calls
  ##############################

  def do_accept_loop(ppid, socket) do
    case :gen_tcp.accept(socket) do
      {:ok, accepted_sock} ->
        {:ok, new_owner_pid} = FlubGw.TcpRoute.Worker.Supervisor.start_child(accepted_sock)
        :ok = :gen_tcp.controlling_process(accepted_sock, new_owner_pid)
        FlubGw.TcpRoute.Worker.take_ownership(new_owner_pid)
        do_accept_loop(ppid, socket)

      _ -> nil
    end
  end

end
