defmodule VisionsUniteWeb.ExpressionComponent do
  use VisionsUniteWeb, :live_view
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
    <%= if Map.has_key?(assigns, :v3) do %>
      <p>
        <%= if is_list(@expression.fully_supporteds) and Enum.count(@expression.fully_supporteds) !== 0 do %>
          <%= link to: "/v3/expression/#{@expression.id}" do %>
            <b>
              / <%= Enum.join(@expression.fully_supporteds, ", ") %> / <%= @expression.title %>
            </b>
          <% end %>
        <% else %>
          <% # Else, this expression is seeking support, and could have multiple groups %>
          <%= if Map.has_key?(assigns, :group) do %>
            <%= link to: "/v3/expression/#{@expression.id}" do %>
              <b>
                / <%= @group %> / <%= @expression.title %>
              </b>
            <% end %>
          <% else %>
            <%= link to: "/v3/expression/#{@expression.id}" do %>
              <b>
                / <%= @expression.title %>
              </b>
            <% end %>
          <% end %>
        <% end %>
      </p>
    <% else %>
      <p>
        <%= if is_list(@expression.fully_supporteds) and Enum.count(@expression.fully_supporteds) !== 0 do %>
          <b>
            / <%= Enum.join(@expression.fully_supporteds, ", ") %> / <%= @expression.title %>
          </b>
        <% else %>
          <% # Else, this expression is seeking support, and could have multiple groups %>
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

            <div>
              <ul>
                <%= for support <- @expression.supports do %>
                  <li><%= support.note %></li>
                <% end %>
              </ul>
            </div>
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
                This expression (<%= @expression.title %>) needs support from <%= group.quorum_count %> out of <%= group.subscriber_count %> (sortition of <%= group.sortition_count%>)

                <%= if is_nil(group.link.id) do %>
                  of <b>all users</b> to be fully supported as a root expression. Currently <%= group.support_count %> supporting.
                <% else %>
                <code><%= group.link.title %></code> subscribers to be fully supported for the <%= group.link.title %> group. Currently <%= group.support_count %> supporting.
                <% end %>
              </p>
            <% end %>
          </div>
        </details>
      </small>
    <% end %>
    """
  end
end

