defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
    <p>
      <%= if is_list(@expression.fully_supporteds) and Enum.count(@expression.fully_supporteds) !== 0 do %>
        <b>
          / <%= Enum.join(@expression.fully_supporteds, ", ") %> / <%= @expression.title %>
        </b>
      <% else %>
        <%= if Map.has_key?(assigns, :group) do %>
          <b>/ <%= @group %> / <%= @expression.title %></b>
        <% else %>
          <b>/ <%= @expression.title %></b>
        <% end %>
      <% end %>
    </p>

    <%= @expression.body %>

    <%= if @expression.author_id == @current_user_id and Map.has_key?(@expression, :supports) and Enum.count(@expression.supports) != 0 do %>
      <small>
        <details>
          <summary>
            user feedback
          </summary>
          <ul>
            <%= for support <- @expression.supports do %>
              <li><%= support.note %></li>
            <% end %>
          </ul>
        </details>
      </small>
    <% end %>

    <small>
      <details>
        <summary>
          more information
        </summary>

        <div>
          <%= for group <- @expression.groups do %>
            <p>
              This expression (<%= @expression.title %>) needs support from <%= group.quorum_count %> out of <%= group.subscriber_count %>

              <%= if is_nil(group.link.id) do %>
                of <b>all users</b> to be fully supported as a root expression.
              <% else %>
              <code><%= group.link.title %></code> subscribers to be fully supported for the <%= group.link.title %> group. Currently <%= group.support_count %> supporting.
              <% end %>
            </p>
          <% end %>
        </div>
      </details>
    </small>
    """
  end
end

