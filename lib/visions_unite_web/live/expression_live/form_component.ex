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
     |> assign(:links, expression.links)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("toggle_linked_expressions", %{ "id" => id }, socket) do
    links =
      if Enum.find(socket.assigns.links, & &1 == id) do
        socket.assigns.links
        |> Enum.filter(& &1 != id)
      else
        [id | socket.assigns.links]
      end

    socket =
      socket
      |> assign(links: links)
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

  defp save_expression(socket, :edit, expression_params) do
    case Expressions.update_expression(socket.assigns.expression, expression_params) do
      {:ok, _expression} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expression updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_expression(socket, :new, expression_params) do
    expression_params =
      Map.put(expression_params, "author_id", socket.assigns.current_user_id)

    case Expressions.create_expression(expression_params) do
      {:ok, expression} ->

        # Try to link...
        socket.assigns.links
        |> Enum.each(fn link ->
          ExpressionLinkages.create_expression_linkage(%{
            expression_id: expression.id,
            link_id: link
          })
        end)

        # Go ahead and subscribe to my own expression
        ExpressionSubscriptions.create_expression_subscription(%{
          expression_id: expression.id,
          user_id: socket.assigns.current_user_id
        })

        # Let's now seek supporters for this expression
        SeekingSupports.seek_supporters(expression)

        {:noreply,
         socket
         |> put_flash(:info, "Expression created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

