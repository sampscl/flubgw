defmodule FlubGwTest do
  use ExUnit.Case
  doctest FlubGw

  test "routes connect" do
    gw_stat = FlubGw.start_gateway({:tcp, local_host: "127.0.0.1", local_port: 10101})
    assert(gw_stat  == :ok)

    route_stat = FlubGw.add_direct_route({:tcp, dest_host: "127.0.0.1", dest_port: 10101}, :a_flub_channel, [route_opts: [], sub_opts: []])
    assert(route_stat == :ok)
  end

  test "route up/down status pubbed" do
    :ok = FlubGw.start_gateway({:tcp, local_host: "127.0.0.1", local_port: 10102})
    route = {:tcp, dest_host: "127.0.0.1", dest_port: 10102}
    :ok = FlubGw.add_direct_route(route, :a_flub_channel, [route_opts: [sub_to_status: true, autoremove: false], sub_opts: []])
    assert_receive(%Flub.Message{channel: :flubgw_route_status, data: %{route: ^route, status: :up}})
    :ok = FlubGw.remove_direct_route(route, :a_flub_channel)
    assert_receive(%Flub.Message{channel: :flubgw_route_status, data: %{route: ^route, status: :down}})
  end

  test "routes disconnect" do
    :ok = FlubGw.start_gateway({:tcp, local_host: "127.0.0.1", local_port: 10103})
    route = {:tcp, dest_host: "127.0.0.1", dest_port: 10103}
    :ok = FlubGw.add_direct_route(route, :a_flub_channel, [route_opts: [autoremove: false], sub_opts: []])
    assert(:ok == FlubGw.remove_direct_route(route, :a_flub_channel))
  end
end
