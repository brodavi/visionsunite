defmodule VisionsUniteWeb.ExpressionComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def render(assigns) do
    expression(assigns)
  end

  def expression(assigns) do
    ~H"""
    <p>
      <%= if is_list(@expression.fully_supporteds) and Enum.count(@expression.fully_supporteds) !== 0 do %>
        <%= link to: "/expression/#{@expression.id}" do %>
          <b>
            / <%= Enum.join(@expression.fully_supporteds, ", ") %> / <%= @expression.title %>
          </b>
        <% end %>
      <% else %>
        <%= link to: "/expression/#{@expression.id}" do %>
          <b>
            / <%= @expression.title %>
          </b>
        <% end %>
      <% end %>
    </p>
    """
  end
end
