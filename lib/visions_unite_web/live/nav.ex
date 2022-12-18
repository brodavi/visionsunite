defmodule VisionsUniteWeb.NavComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def render(assigns) do
    nav(assigns)
  end

  def nav(assigns) do
    if Map.has_key?(assigns, :current_user_id) do
      ~H"""
      <nav>
        <%= if @active == :seeking_support do %>
          <a href="#" class="active">Seeking Your Support</a>
        <% else %>
          <%= link "Seeking Your Support", to: "/expressions_seeking_my_support" %>
        <% end %>

        <%= if @active == :fully_supported do %>
          <a href="#" class="active">Fully Supported for You</a>
        <% else %>
          <%= link "Fully Supported for You", to: "/fully_supported_expressions" %>
        <% end %>

        <%= if @active == :my_subscriptions do %>
          <a href="#" class="active">My Conversations</a>
        <% else %>
          <%= link "My Conversations", to: "/my_subscriptions" %>
        <% end %>

        <%= if @active == :my_expressions do %>
          <a href="#" class="active">My Expressions</a>
        <% else %>
          <%= link "My Expressions", to: "/my_expressions" %>
        <% end %>

        <%= if @active == :ignored_expressions do %>
          <a href="#" class="active">Muted</a>
        <% else %>
          <%= link "Muted", to: "/ignored_expressions" %>
        <% end %>

        <%= if @active == :all_expressions do %>
          <a href="#" class="active">ALL</a>
        <% else %>
          <%= link "ALL", to: "/all_expressions" %>
        <% end %>
      </nav>
      """
    else
      ~H"""
      """
    end
  end
end
