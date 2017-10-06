# FlubGw.HttpRoute.Worker
# route

defmodule FlubGw.HttpRoute.Worker.Supervisor do
  use Supervisor

  #############
  # API
  #############

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def start_child(route) do
    Supervisor.start_child(__MODULE__, [route])
  end

  ##############################
  # GenServer Callbacks
  ##############################

  def init([]) do
    children = [
      worker(FlubGw.HttpRoute.Worker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ##############################
  # Internal
  ##############################

end
