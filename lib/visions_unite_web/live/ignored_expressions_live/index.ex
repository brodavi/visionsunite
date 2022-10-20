defmodule VisionsUniteWeb.IgnoredExpressionsLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUniteWeb.ExpressionComponent
  alias VisionsUniteWeb.NavComponent

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      VisionsUniteWeb.SharedPubSub.subscribe("sortitions")
      VisionsUniteWeb.SharedPubSub.subscribe("support")
      VisionsUniteWeb.SharedPubSub.subscribe("supported_expressions")
    end

    user_id = session["current_user_id"]

    ignored_expressions =
      list_ignored_expressions(user_id)

    socket =
      socket
      |> assign(:debug, System.get_env("DEBUG"))
      |> assign(:current_user_id, user_id)
      |> assign(:ignored_expressions, ignored_expressions)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Expressions Seeking My Support")
  end

  @impl true
  def handle_event("subscribe", %{"expression_id" => expression_id}, socket) do
    user_id = socket.assigns.current_user_id

    ExpressionSubscriptions.create_expression_subscription(%{
      expression_id: expression_id,
      user_id: user_id,
      subscribe: true
    })

    ignored_expressions =
      list_ignored_expressions(user_id)

    socket =
      socket
      |> put_flash(:info, "Successfully subscribed to expression. Thank you!")
      |> assign(:ignored_expressions, ignored_expressions)
    {:noreply, socket}
  end


  defp list_ignored_expressions(user_id) do
    Expressions.list_ignored_expressions(user_id)
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
  end
end

