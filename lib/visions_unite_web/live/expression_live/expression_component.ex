defmodule VisionsUniteWeb.ExpressionComponent do
  use Phoenix.Component

  def expression(assigns) do
    ~H"""
      <div>
        <p>
          <%= assigns.expression.body %>: supported by <%= assigns.expression.support %> users

          <%= if VisionsUnite.Expressions.is_expression_fully_supported(assigns.expression, assigns.quorum_needed) do %>
            (supported!)
          <% end %>
        </p>

        <small>
          <b>linked expressions:</b>
          <%= for parent <- assigns.expression.parents do %>
            <%= parent %>
          <% end %>
        </small>
      </div>
    """
  end
end

