defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
    <p>
      <b>
        <%= @expression.title %>
      </b>

      <%= if is_list(@expression.fully_supporteds) and Enum.count(@expression.fully_supporteds) !== 0 do %>
        <small>
        <small>
          ( because you are subscribed to:
          <%= for fs <- @expression.fully_supporteds do %>
            <%= fs %>&nbsp;
          <% end %>
          )
        </small>
        </small>
      <% end %>
    </p>

    <small><%= @expression.body %></small>

    <%= if @expression.author_id == @current_user_id and Map.has_key?(@expression, :supports) and Enum.count(@expression.supports) != 0 do %>
      <small>
        <details>
          <summary>
            <b>User feedback:</b>
          </summary>
          <ul>
            <%= for support <- @expression.supports do %>
              <li><%= support.note %></li>
            <% end %>
          </ul>
        </details>
      </small>
    <% end %>

    <%= if @debug do %>
      <small>

        <%= if false do %>
          <%= for linked_expression <- @expression.linked_expressions do %>
            <details>
              <summary>
                #<%= linked_expression.link.title %>
              </summary>
              Linked expression: <code><%= linked_expression.link.title %></code> is supported by <%= linked_expression.support_count %> subscribers. (<%= linked_expression.quorum_count %> out of <%= linked_expression.subscriber_count %> are needed to be fully supported)
            </details>
          <% end %>
        <% else %>
          <div>
            <%= for linked_expression <- @expression.linked_expressions do %>
              #<%= linked_expression.link.title %>
            <% end %>
          </div>
        <% end %>

        <details>
          <summary>
            support details
          </summary>
          <%= for group <- @expression.groups do %>
            <div>
              This expression needs support from <%= group.quorum_count %> out of <%= group.subscriber_count %>

              <%= if is_nil(group.link.id) do %>
                of <b>all users</b> to be fully supported as a root expression.
              <% else %>
              <code><%= group.link.title %></code> subscribers to be fully supported for the <%= group.link.title %> group.
              <% end %>

              <br>
              Currently <%= group.support_count %> supporting.
            </div>
          <% end %>
        </details>

      </small>


    <% else %>
      <div>
        <%= for linked_expression <- @expression.linked_expressions do %>
          <small><i>#<%= linked_expression.link.title %></i></small>
        <% end %>
      </div>
    <% end %>
    """
  end
end

