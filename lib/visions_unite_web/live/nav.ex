defmodule VisionsUniteWeb.NavComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def render(assigns) do
    nav(assigns)
  end

  def nav(assigns) do
    ~H"""
    <nav>
      <%= if @active == :important_groups do %>
        <a href="#" class="active">All Important Groups</a>
      <% else %>
        <%= link "Important Groups", to: "/important_groups" %>
      <% end %>

      <%= if @current_user_id do %>
        <%= if @active == :my_subscribed_groups do %>
          <a href="#" class="active">My Important Groups</a>
        <% else %>
          <%= link "My Important Groups", to: "/my_subscribed_groups" %>
        <% end %>
      <% end %>

      <%= if @active == :important_messages do %>
        <a href="#" class="active">All Important Messages</a>
      <% else %>
        <%= link "All Important Messages", to: "/important_messages" %>
      <% end %>

      <%= if @current_user_id do %>
        <%= if @active == :my_subscribed_messages do %>
          <a href="#" class="active">My Important Messages</a>
        <% else %>
          <%= link "My Important Messages", to: "/my_subscribed_messages" %>
        <% end %>
      <% end %>
    </nav>
    """
  end
end
