defmodule LiveViewCounterWeb.Counter do
  use Phoenix.LiveView

  alias LiveViewCounter.CountServer
  alias LiveViewCounter.Presence
  alias Phoenix.PubSub

  @topic CountServer.topic()
  @topic_presence "presence"

  def render(assigns) do
    ~H"""
    <div>
      <h1>The count is: <%= @val %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>
      <h1>Current users: <%= @present %></h1>
      <h2>Session: <%= @session_id %></h2>
    </div>
    """
  end

  def mount(_params, %{"session_id" => session_id}, socket) do
    PubSub.subscribe(LiveViewCounter.PubSub, @topic)
    Presence.track(self(), @topic_presence, socket.id, %{})
    LiveViewCounterWeb.Endpoint.subscribe(@topic_presence)

    initial_present =
      Presence.list(@topic_presence)
      |> map_size()

    {:ok,
     assign(socket,
       val: CountServer.current(),
       present: initial_present,
       session_id: session_id
     )}
  end

  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, :val, CountServer.incr())}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, :val, CountServer.decr())}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, :val, count)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do
    new_present = present + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :present, new_present)}
  end
end
