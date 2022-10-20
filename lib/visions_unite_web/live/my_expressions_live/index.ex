defmodule VisionsUniteWeb.MyExpressionsLive.Index do
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

    my_expressions =
      list_my_expressions(user_id)
      |> filter_members_of(ignored_expressions)

    socket =
      socket
      |> assign(:debug, System.get_env("DEBUG"))
      |> assign(:current_user_id, user_id)
      |> assign(:my_expressions, my_expressions)
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

  defp list_ignored_expressions(user_id) do
    Expressions.list_ignored_expressions(user_id)
  end

  defp list_my_expressions(user_id) do
    Expressions.list_expressions_authored_by_user(user_id)
    |> Expression.annotate_with_supports()
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
  end

  defp filter_members_of(expressions, reject_expressions) do
    expressions
    |> Enum.filter(fn expr ->
      !Enum.any?(reject_expressions, fn expression ->
        expression.id == expr.id
      end)
    end)
  end
end


