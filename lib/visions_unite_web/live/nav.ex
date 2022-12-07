defmodule VisionsUniteWeb.NavComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def render(assigns) do
    nav(assigns)
  end

  def nav(assigns) do
    ~H"""
    <nav>
      <%= if @active == :seeking_support do %>
        <a href="#" class="active">Seeking Support</a>
      <% else %>
        <%= link "Seeking Support", to: "/#{@version}/expressions_seeking_my_support" %>
      <% end %>

      <%= if @active == :fully_supported do %>
        <a href="#" class="active">Fully Supported</a>
      <% else %>
        <%= link "Fully Supported", to: "/#{@version}/fully_supported_expressions" %>
      <% end %>

      <%= if @active == :my_subscriptions do %>
        <a href="#" class="active">Expressions I have Joined</a>
      <% else %>
        <%= link "Expressions I have Joined", to: "/#{@version}/my_subscriptions" %>
      <% end %>

      <%= if @active == :my_expressions do %>
        <a href="#" class="active">My Expressions</a>
      <% else %>
        <%= link "My Expressions", to: "/#{@version}/my_expressions" %>
      <% end %>

      <%= if @active == :ignored_expressions do %>
        <a href="#" class="active">Ignored</a>
      <% else %>
        <%= link "Ignored", to: "/#{@version}/ignored_expressions" %>
      <% end %>

      <%= if @active == :all_expressions do %>
        <a href="#" class="active">ALL</a>
      <% else %>
        <%= link "ALL", to: "/#{@version}/all_expressions" %>
      <% end %>
    </nav>
    """
  end
end
