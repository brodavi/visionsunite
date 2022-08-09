defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
      <div>
        <div>
          <div><b><%= @expression.title %></b></div>

          <%= if Enum.count(@expression.links) == 0 do %>
            <small>supported by <%= @expression.support %> users <%= "(#{@expression.quorum_count} out of #{@expression.subscription_count} needed)" %></small>
          <% end %>

          <%= for link <- @expression.links do %>
            <details>
              <summary>
                <button><%= link.title %></button>
              </summary>
              <small>Linked expression: <code><%= link.title %></code>'s group (<%= link.subscription_count %> users) supported by <%= link.support %> users <%= "(#{link.quorum_count} out of #{link.subscription_count} needed to be fully supported)" %></small>
            </details>
          <% end %>

          <%= if Map.has_key?(@expression, :notes) do %>
            <br>
            <small>
              <details>
                <summary>
                  <b>User feedback:</b>
                </summary>
                <ul>
                  <%= for note <- @expression.notes do %>
                    <li><%= note %></li>
                  <% end %>
                </ul>
              </details>
            </small>
          <% end %>
        </div>
      </div>
    """
  end
end

