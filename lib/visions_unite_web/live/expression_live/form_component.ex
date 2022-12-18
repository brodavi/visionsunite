defmodule VisionsUniteWeb.ExpressionLive.FormComponent do
  use VisionsUniteWeb, :live_component

  alias VisionsUnite.Expressions

  @impl true
  def update(%{expression: expression} = assigns, socket) do
    changeset = Expressions.change_expression(expression)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"expression" => expression_params}, socket) do
    changeset =
      socket.assigns.expression
      |> Expressions.change_expression(expression_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"expression" => expression_params}, socket) do
    expression_params = Map.put(expression_params, "author_id", socket.assigns.current_user_id)
    linked_expressions = [expression_params["linked_expression_id"]]

    case Expressions.create_expression(expression_params, linked_expressions) do
      {:ok, _expression, _seeking_supports} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expression created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
