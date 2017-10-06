defmodule FlubGw.Router do
  @callback route_msg(FlubGw.route(), %Flub.Message{}) :: :ok | {:error, any()}
end
