# route_or_socket
# FlubGw.TcpRoute.Worker

defmodule FlubGw.TcpRoute.Worker do
  @behaviour FlubGw.Router
  use GenServer
  import ShorterMaps
  require Logger

  @keep_alive_interval_ms 15_000

  ##############################
  # API
  ##############################

  @spec route_msg(FlubGw.route(), %Flub.Message{}) :: :ok | {:error, any()}
  @doc """
  Route a message.
  """
  def route_msg(route, msg) do
    {:n, :l, {__MODULE__, route}}
    |> :gproc.lookup_pid()
    |> GenServer.call({:route_msg, route, msg})
  end

  def stop(route_or_socket) do
    {:n, :l, {__MODULE__, route_or_socket}}
    |> :gproc.lookup_pid()
    |> GenServer.stop()
  end

  def start_link(route_or_socket) do
    GenServer.start_link(__MODULE__, [route_or_socket])
  end

  defmodule State do
    @doc false
    defstruct [
      route: nil, # the route
      socket: nil, # the socket
      recv_buf: <<>>, # receive buffer
    ]
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([{:tcp, dest_host: dest_host, dest_port: dest_port} = route]) do
    Logger.debug("Route worker starting on route #{inspect(route)}")
    {:ok, ip_address} = :inet.parse_address(to_charlist(dest_host))
    {:ok, socket} = :gen_tcp.connect(ip_address, dest_port, [], 5_000)
    Process.send_after(self(), :keep_alive, @keep_alive_interval_ms)

    :gproc.reg({:n, :l, {__MODULE__, route}})
    {:ok, %State{route: route, socket: socket}}
  end

  def init([socket]) do
    Logger.debug("Route worker starting on socket #{inspect(socket)}")
    :gproc.reg({:n, :l, {__MODULE__, socket}})
    :ok = :gen_tcp.controlling_process(socket, self())
    :ok = :inet.setopts(socket, active: true)
    {:ok, %State{socket: socket}}
  end

  def handle_call({:route_msg, route, msg}, _from, state) do
    bin_msg = :erlang.term_to_binary({route, msg})
    msg_size = <<byte_size(msg) :: size(32)>>
    :ok = :gen_tcp.send(state.socket, msg_size <> bin_msg)
    {:reply, :ok, state}
  end

  def handle_info(:keep_alive, ~M{socket, route} = state) do
    Process.send_after(self(), :keep_alive, @keep_alive_interval_ms)
    msg = :erlang.term_to_binary({route, :keep_alive})
    msg_size = <<byte_size(msg) :: size(32)>>
    :ok = :gen_tcp.send(socket, msg_size <> msg)
    {:noreply, state}
  end

  def handle_info({:tcp, _pid, msg}, ~M{recv_buf} = state) do
    {:noreply, process_recv_buf(%{state| recv_buf: recv_buf <> msg})}
  end

  ##############################
  # Internal Calls
  ##############################

  def process_recv_buf(%State{recv_buf: <<>>} = state), do: state
  def process_recv_buf(%State{recv_buf: <<msg_size :: size(32), data :: binary>>} = state) do
    case msg_size <= byte_size(data) do
      false -> state # need more data
      true ->
        <<msg :: bytes-size(msg_size), rest :: binary>> = data
        %{state| recv_buf: rest}
        |> process_msg(msg)
        |> process_recv_buf()
    end
  end

  def process_msg(state, msg) do
    case :erlang.binary_to_term(msg) do
      {_route, %Flub.Message{data: flub_data, channel: flub_channel}} ->
        Flub.pub(flub_data, flub_channel)
        state

      _ -> state
    end
  end
end
