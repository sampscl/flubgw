# addr, port
# FlubGw.TcpGateway.Listener.Worker

defmodule FlubGw.TcpGateway.Listener.Worker do
  use GenServer
  import ShorterMaps
  require Logger

  @simultaneous_acceptors 1

  ##############################
  # API
  ##############################

  def stop(addr, port) do
    :gproc.lookup_pid({:n, :l, {__MODULE__, addr, port}}) |> GenServer.stop()
  end

  def start_link(addr, port) do
    GenServer.start_link(__MODULE__, [addr, port])
  end

  defmodule State do
    @doc false
    defstruct [
      addr: nil, # address
      port: nil, # port
      socket: nil, # socket
    ]
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([addr, port]) do
    :gproc.reg({:n, :l, {__MODULE__, addr, port}})
    {:ok, ip_address} = :inet.parse_address(to_charlist(addr))
    {:ok, socket} = :gen_tcp.listen(port, ip: ip_address, active: false)
    Enum.each(1..@simultaneous_acceptors, fn(_) -> FlubGw.TcpGateway.Acceptor.Worker.Supervisor.start_child(socket) end)
    {:ok, ~M{State, addr, port, socket}}
  end

  ##############################
  # Internal Calls
  ##############################

end
