#
# FlubGw.Route.Manager

defmodule FlubGw.Route.Manager do
  use GenServer
  import ShorterMaps
  require Logger
  require LoggerUtils

  ##############################
  # API
  ##############################

  def add_direct_route(route, channel, opts), do: call({:add_direct_route, route, channel, opts})
  def remove_direct_route(route, channel), do: call({:remove_direct_route, route, channel})
  def eliminate_direct_route(route, channel), do: call({:eliminate_direct_route, route, channel})

  def call(args) do
    GenServer.call(__MODULE__, args)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  defmodule State do
    @doc false
    defstruct [
      routes: %{}, # k: {FlubGw.route(), channel}, v: reference count
      channels: %{}, # k: channel, v: [FlubGw.route()]
    ]
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    {:ok, %State{}}
  end

  def handle_call({:add_direct_route, route, channel, opts}, _from, state) do
    {:reply, :ok, do_add_direct_route(state, route, channel, opts)}
  end

  def handle_call({:remove_direct_route, route, channel}, _from, state) do
    {:reply, :ok, do_remove_direct_route(state, route, channel)}
  end

  def handle_call({:eliminate_direct_route, route, channel}, _from, state) do
    {:reply, :ok, do_eliminate_direct_route(state, route, channel)}
  end

  def handle_info(%Flub.Message{data: _data, channel: channel} = msg, state) do
    routes = Map.get(state.channels, channel, [])
    {:noreply, send_msg_to_routes(state, msg, routes)}
  end

  ##############################
  # Internal Calls
  ##############################

  def send_msg_to_routes(state, _msg, []), do: state
  def send_msg_to_routes(state, msg, [route | more_routes]) do
    case route do
      {:tcp, _} -> :ok = FlubGw.TcpRoute.Worker.route_msg(route, msg)
      _            -> LoggerUtils.trace("bad route: #{inspect route}")
    end
    send_msg_to_routes(state, msg, more_routes)
  end

  def add_new_route(~M{routes} = state, route, channel), do: %{state| routes: Map.put(routes, {route, channel}, 1)}
  def inc_route_refs(~M{routes} = state, route, channel, old_ref), do: %{state| routes: Map.put(routes, {route, channel}, 1 + old_ref)}
  def dec_route_refs(~M{routes} = state, route, channel, old_ref), do: %{state| routes: Map.put(routes, {route, channel}, old_ref - 1)}
  def del_old_route(~M{routes} = state, route, channel), do: %{state| routes: Map.delete(routes, {route, channel})}

  def add_route_for_channel(~M{channels} = state, route, channel) do
    new_channel_list = [route|  Map.get(channels, channel, [])]
    new_channels = Map.put(channels, channel, new_channel_list)
    %{state| channels: new_channels}
  end

  def del_route_for_channel(~M{channels} = state, route, channel) do
    new_channel_list =
      channels
      |> Map.get(channel, [])
      |> List.delete(route)

    new_channels = case new_channel_list do
      [] -> Map.delete(channels, channel)
      _  -> Map.put(channels, channel, new_channel_list)
    end
    %{state| channels: new_channels}
  end

  def do_add_direct_route(~M{routes} = state, route, channel, [route_opts: _route_opts, sub_opts: sub_opts] = _opts) do
    new_state = case Map.get(routes, {route, channel}, 0) do
      0 -> # make a new route for this {route, channel}
        Flub.pub(%{route: route, status: :up}, :flubgw_route_status)
        Flub.sub(channel, sub_opts)
        state
        |> start_route_worker(route)
        |> add_route_for_channel(route, channel)
        |> add_new_route(route, channel)

      ref_cnt -> # increment reference count for this {route, channel}
        inc_route_refs(state, route, channel, ref_cnt)
    end
    new_state
  end

  def do_remove_direct_route(~M{routes} = state, route, channel) do
    new_state = case Map.get(routes, {route, channel}, 0) do
      0 -> # delete this {route, channel} (should never get here)
        state
        |> stop_route_worker(route)
        |> del_old_route(route, channel)
        |> del_route_for_channel(route, channel)

      1 -> # unsubscribe and delete this {route, channel}
        Flub.unsub(channel)
        state
        |> stop_route_worker(route)
        |> del_old_route(route, channel)
        |> del_route_for_channel(route, channel)

      ref_cnt -> # unsubscribe this {route, channel} and decrement ref count
        Flub.unsub(channel)
        dec_route_refs(state, route, channel, ref_cnt)
    end
    new_state
  end

  def do_eliminate_direct_route(~M{routes} = state, route, channel) do
    case Map.has_key?(routes, {route, channel}) do
      false -> state
      true  ->
        state
        |> do_remove_direct_route(route, channel)
        |> do_eliminate_direct_route(route, channel)
    end
  end

  def start_route_worker(state, {:tcp, dest_host: _, dest_port: _} = route) do
    {:ok, _} = FlubGw.TcpRoute.Worker.Supervisor.start_child(route)
    state
  end

  def stop_route_worker(state, {:tcp, dest_host: _, dest_port: _} = route) do
    FlubGw.TcpRoute.Worker.Supervisor.stop_child(route)
    state
  end
end
