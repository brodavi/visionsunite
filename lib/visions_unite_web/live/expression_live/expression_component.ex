defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
      <div>
        <div>
          <%= @expression.title %>: supported by <%= @expression.support %> users <%= if Map.has_key?(assigns, :show_quorum_and_group_count) do "(#{@expression.quorum} out of #{@expression.group_count} needed)" end %>

          <%= if Map.has_key?(assigns, :show_subscribe) do %>
            <button phx-click="subscribe" phx-value-expression_id={@expression.id}>Subscribe</button>
          <% end %>

          <%= if Map.has_key?(assigns, :show_unsubscribe) do %>
            <button phx-click="unsubscribe" phx-value-expression_id={@expression.id}>Unsubscribe</button>
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

