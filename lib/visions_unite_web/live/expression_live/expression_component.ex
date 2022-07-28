defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
      <div>
        <div>
          <div><b><%= @expression.title %></b></div>
          <%= for {link, idx} <- Enum.with_index(@expression.links) do %>
            <small>Linked expression: <%= link %>'s group supported by <%= Enum.at(@expression.supports, idx) %> users <%= if Map.has_key?(assigns, :show_quorum_and_group_count) and @show_quorum_and_group_count do "(#{Enum.at(@expression.quorums, idx)} out of #{Enum.at(@expression.group_counts, idx)} needed)" end %></small>
          <% end %>

          <%= if Map.has_key?(assigns, :show_subscribe) do %>
            <button phx-click="subscribe" phx-value-expression_id={@expression.id}>Subscribe</button>
          <% end %>

          <%= if Map.has_key?(assigns, :show_unsubscribe) do %>
            <button phx-click="unsubscribe" phx-value-expression_id={@expression.id}>Unsubscribe</button>
          <% end %>
        </div>

        <%= if Enum.count(@expression.links) != 0 do %>
          <small>
            <%= for link <- @expression.links do %>
              <button>#<%= link %></button>
            <% end %>
          </small>
        <% end %>
      </div>
    """
  end
end

