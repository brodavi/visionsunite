defmodule VisionsUniteWeb.NavComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def nav(assigns) do
    ~H"""
    <nav>
      <%= if @active == "seeking_support" do %>
        <a href="#" class="active">Seeking Support</a>
      <% else %>
        <%= link "Seeking Support", to: "/v2/expressions_seeking_my_support" %>
      <% end %>

      <%= if @active == "fully_supported" do %>
        <a href="#" class="active">Fully Supported</a>
      <% else %>
        <%= link "Fully Supported", to: "/v2/fully_supported_expressions" %>
      <% end %>

      <%= if @active == "my_subscriptions" do %>
        <a href="#" class="active">Expressions I have Joined</a>
      <% else %>
        <%= link "Expressions I have Joined", to: "/v2/my_subscriptions" %>
      <% end %>

      <%= if @active == "my_expressions" do %>
        <a href="#" class="active">My Expressions</a>
      <% else %>
        <%= link "My Expressions", to: "/v2/my_expressions" %>
      <% end %>

      <%= if @active == "ignored_expressions" do %>
        <a href="#" class="active">Ignored</a>
      <% else %>
        <%= link "Ignored", to: "/v2/ignored_expressions" %>
      <% end %>
    </nav>
    """
  end
end

