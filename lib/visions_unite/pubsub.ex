defmodule VisionsUniteWeb.SharedPubSub do
  def subscribe(channel) do
    Phoenix.PubSub.subscribe(VisionsUnite.PubSub, channel)
  end

  def broadcast({:error, _reason} = error, _event), do: error
  def broadcast({:ok, data}, event, channel) do
    Phoenix.PubSub.broadcast(VisionsUnite.PubSub, channel, {event, data})
    {:ok, data }
  end
end

