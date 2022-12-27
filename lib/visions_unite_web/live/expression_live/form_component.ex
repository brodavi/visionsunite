defmodule VisionsUniteWeb.ExpressionLive.FormComponent do
  use VisionsUniteWeb, :live_component

  alias VisionsUnite.Expressions

  @impl true
  def update(%{expression: expression} = assigns, socket) do
    changeset = Expressions.change_expression(expression)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"expression" => expression_params}, socket) do
    changeset =
      socket.assigns.expression
      |> Expressions.change_expression(expression_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save_group", %{"expression" => expression_params}, socket) do
    expression_params = Map.put(expression_params, "author_id", socket.assigns.current_user_id)
    case Expressions.create_expression(expression_params) do
      {:ok, _expression, _seeking_supports} ->
        {:noreply,
         socket
         |> put_flash(:info, "Group created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("save_message", %{"expression" => expression_params}, socket) do
    expression_params = Map.put(expression_params, "author_id", socket.assigns.current_user_id)
    linked_expressions = [expression_params["linked_expression_id"]]

    case Expressions.create_expression(expression_params, linked_expressions) do
      {:ok, _expression, _seeking_supports} ->
        {:noreply,
         socket
         |> put_flash(:info, "Message created successfully")
         |> push_redirect(to: "/expression/#{expression_params["linked_expression_id"]}")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
