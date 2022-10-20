defmodule VisionsUniteWeb.FullySupportedExpressionsLive.Index do
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

    my_subscriptions =
      list_my_subscriptions(user_id)
      |> filter_members_of(my_expressions)

    fully_supported_expressions =
      list_fully_supported_expressions(user_id)
      |> filter_members_of(ignored_expressions)
      |> filter_members_of(my_subscriptions)

    socket =
      socket
      |> assign(:debug, System.get_env("DEBUG"))
      |> assign(:current_user_id, user_id)
      |> assign(:fully_supported_expressions, fully_supported_expressions)
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

    my_expressions =
      list_my_expressions(user_id)

    my_subscriptions =
      list_my_subscriptions(user_id)
      |> filter_members_of(my_expressions)

    fully_supported_expressions =
      list_fully_supported_expressions(user_id)
      |> filter_members_of(ignored_expressions)
      |> filter_members_of(my_subscriptions)

    socket =
      socket
      |> put_flash(:info, "Successfully subscribed to expression. Thank you!")
      |> assign(:my_subscriptions, my_subscriptions)
      |> assign(:fully_supported_expressions, fully_supported_expressions)
      |> assign(:ignored_expressions, ignored_expressions)
    {:noreply, socket}
  end

  #
  # NOTE: this is a "reverse subscribe." This is needed because
  #       if a user wants to ignore a fully-supported expression, she cannot. They are by-default shown to everyone.
  #
  @impl true
  def handle_event("ignore", %{"expression_id" => expression_id}, socket) do
    user_id = socket.assigns.current_user_id

    # TODO: do the more efficient filtering expression, don't hit the DB

    # TODO: do upsert instead of this
    existing_subscription =
      ExpressionSubscriptions.get_expression_subscription_for_expression_and_user(expression_id, user_id)

    result =
      case existing_subscription do
        nil ->
          ExpressionSubscriptions.create_expression_subscription(%{
            expression_id: expression_id,
            user_id: user_id,
            subscribe: false
          })
        _ ->
          ExpressionSubscriptions.update_expression_subscription(
            existing_subscription, %{
              subscribe: false
            }
          )
      end

    ignored_expressions =
      list_ignored_expressions(user_id)

    my_expressions =
      list_my_expressions(user_id)
      |> filter_members_of(ignored_expressions)

    my_subscriptions =
      list_my_subscriptions(user_id)
      |> filter_members_of(my_expressions)

    fully_supported_expressions =
      list_fully_supported_expressions(user_id)
      |> filter_members_of(ignored_expressions)
      |> filter_members_of(my_subscriptions)

    socket =
      socket
      |> put_flash(:info, "Successfully ignored expression.")
      |> assign(:fully_supported_expressions, fully_supported_expressions)
      |> assign(:ignored_expressions, ignored_expressions)
      |> assign(:my_expressions, my_expressions)

    {:noreply, socket}
  end

  defp list_ignored_expressions(user_id) do
    Expressions.list_ignored_expressions(user_id)
  end

  defp list_my_subscriptions(user_id) do
    Expressions.list_subscribed_expressions_for_user(user_id)
  end

  defp list_my_expressions(user_id) do
    Expressions.list_expressions_authored_by_user(user_id)
  end

  defp list_fully_supported_expressions(user_id) do
    Expressions.list_fully_supported_expressions(user_id)
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
    |> Expression.annotate_with_fully_supporteds(user_id)
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

