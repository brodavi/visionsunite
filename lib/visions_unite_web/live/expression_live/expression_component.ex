defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
      <div>
        <div>
          <%= @expression.body %>: supported by <%= @expression.support %> users

          <%= if Map.has_key?(assigns, :show_subscribe) do %>
            <button phx-click="subscribe" phx-value-expression_id={@expression.id}>Subscribe</button>
          <% end %>
        </div>

        <%= if Enum.count(@expression.parents) != 0 do %>
          <small>
            <b>linked expressions:</b>
            <%= for parent <- @expression.parents do %>
              <%= parent %>
            <% end %>
          </small>
        <% end %>
      </div>
    """
  end
end

