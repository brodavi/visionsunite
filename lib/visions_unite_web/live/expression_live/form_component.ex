defmodule VisionsUniteWeb.ExpressionLive.FormComponent do
  use VisionsUniteWeb, :live_component

  alias VisionsUnite.Expressions
  alias VisionsUnite.ExpressionLinkages
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.SeekingSupports

  @impl true
  def update(%{expression: expression} = assigns, socket) do
    changeset = Expressions.change_expression(expression)

    {:ok,
      socket
      |> assign(assigns)
      |> assign(:linked_expressions, expression.linked_expressions)
      |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("toggle_linked_expressions", %{ "id" => id }, socket) do
    linked_expressions =
      if Enum.find(socket.assigns.linked_expressions, & &1 == id) do
        socket.assigns.linked_expressions
        |> Enum.filter(& &1 != id)
      else
        [id | socket.assigns.linked_expressions]
      end

    socket =
      socket
      |> assign(linked_expressions: linked_expressions)
    {:noreply, socket}
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
    save_expression(socket, socket.assigns.action, expression_params)
  end

  defp save_expression(socket, :new, expression_params) do
    expression_params =
      Map.put(expression_params, "author_id", socket.assigns.current_user_id)

    case Expressions.create_expression(expression_params, socket.assigns.linked_expressions) do
      {:ok, expression, _seeking_supports} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expression created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

