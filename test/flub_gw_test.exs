defmodule FlubGwTest do
  use ExUnit.Case
  doctest FlubGw

  test "local routes connect" do
    gw_stat = FlubGw.start_gateway({:tcp, local_host: "127.0.0.1", local_port: 10101})
    assert(gw_stat  == :ok)

    route_stat = FlubGw.add_direct_route({:tcp, dest_host: "127.0.0.1", dest_port: 10101}, :a_flub_channel, [route_opts: [], sub_opts: []])
    assert(route_stat == :ok)
  end

end
