defmodule FlubGw do
  @moduledoc """
  FlubGw: a gateway system for distributing Flub outside of a node network.

  # Some definitions

  **Channel**
  A channel is as defined for `Flub.sub`.

  **Route**
  A route is a connection between two endpoints. A route is created with a
  channel to subscribe to on the local end of the route. Flub messages
  received on the local end are sent through the route to the remote end and
  re-published there via `Flub.pub`.

  **Gateway**
  A gateway is a server that accepts messages from a `route` and re-publishes
  then remotely
  """

  require Logger

  @type tcp_route :: {:tcp, dest_host: String.t, dest_port: non_neg_integer()}
  @type http_route :: {:http, dest_host: String.t, dest_port: non_neg_integer()}
  @type route :: tcp_route() | http_route()

  @type tcp_gateway :: {:tcp, local_host: String.t, local_port: non_neg_integer()}
  @type gateway :: tcp_gateway()

  @spec add_direct_route(route(), atom(), [route_opts: list(), sub_opts: list()]) :: :ok | {:error, any()}
  @doc """
  Adds a route for flub messages on `channel` to the remote flub
  gateway in `route`.

  route_opts:
  1. sub_to_status: True to Flub.sub to route status reports. You will receive
    reports like this: %{route: {kind, target, opts}, status: :up | :down}
  2. autoremove: True to automatically remove this route when the calling pid
  dies. False keeps the route around until it is manually removed. Do not set
  autoremove to true and then call `remove_direct_route` or
  `eliminate_direct_route`; doing so will cause a double-removal situation.

  sub_opts:
  * See `Flub.sub` documentation.

  Returns `:ok` on success, `{:error, reason}` on failure.
  """
  def add_direct_route(route, channel, [route_opts: route_opts, sub_opts: _sub_opts] = opts) do
    case FlubGw.Route.Manager.add_direct_route(route, channel, opts) do
      :ok ->
        # do ghoul outside of route manager for ghoul safety
        if(Keyword.get(route_opts, :autoremove, true)) do
          Ghoul.summon({route, channel}, on_death: fn({route, channel}) -> remove_direct_route(route, channel) end)
        end
        :ok

      {:error, reason} -> {:error, reason}
    end
  end

  @spec remove_direct_route(route(), atom()) :: :ok | {:error, any()}
  @doc """
  Removes a route added by `add_direct_route`. Removing a direct route is only
  required if gateway routing is transient. That is: there is no harm in adding
  a route that you intend to use forever and not bothering to ever remove it.

  Returns `:ok` on success, `{:error, reason}` on failure.
  """
  def remove_direct_route(route, channel), do: FlubGw.Route.Manager.remove_direct_route(route, channel)

  @spec eliminate_direct_route(route(), atom()) :: :ok | {:error, any()}
  @doc """
  Eliminates a route added by one or more calls to `add_direct_route`. Calling
  this will force the route's reference count to zero and thereby remove it
  completely.

  Returns `:ok`.
  """
  def eliminate_direct_route(route, channel), do: FlubGw.Route.Manager.eliminate_direct_route(route, channel)

  @spec start_gateway(gateway()) :: :ok | {:error, any()}
  @doc """
  Start a gateway server for `gateway`. The server will accept incoming route
  connections and republish any messages received.

  Returns `:ok` on success, `{:error, reason}` on failure.
  """
  def start_gateway({:tcp, local_host: addr, local_port: port} = _gateway) do
    case FlubGw.TcpGateway.Listener.Worker.Supervisor.start_child(addr, port) do
      {:ok, _} -> :ok
      err      -> {:error, err}
    end
  end

end
