defmodule VisionsUniteWeb.ExpressionLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.ExpressionLinkages
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.FullySupporteds
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Supports
  alias VisionsUniteWeb.ExpressionComponent

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

    my_seeking_supports =
      list_my_seeking_supports(user_id)

    socket =
      socket
      |> assign(:debug, System.get_env("DEBUG"))
      |> assign(:current_user_id, user_id)
      |> assign(:my_expressions, my_expressions)

    # TODO we should Enum.group_by(& &1.linked_expressions) here, so that it groups subscribed expressions by "parents"
      |> assign(:my_subscriptions, my_subscriptions)
    # TODO we should have a separate page for ignored expressions (fully-supported expressions that the user is intentionally ignoring)
      |> assign(:fully_supported_expressions, fully_supported_expressions)
      |> assign(:ignored_expressions, ignored_expressions)
      |> assign(:my_seeking_supports, my_seeking_supports)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Expression")
    |> assign(:expression, %Expression{linked_expressions: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Expressions")
    |> assign(:expression, nil)
  end

  defp apply_action(socket, :my_subscriptions, _params) do
    socket
    |> assign(:page_title, "My Expressions")
    |> assign(:expression, nil)
  end

  @impl true
  def handle_event("my_support", %{"support_form" => %{
    "expression_id" => expression_id,
    "support" => support,
    "note" => note,
    "for_group_id" => for_group_id
  }}, socket) do
    user_id = socket.assigns.current_user_id

    Supports.create_support(%{
      support: support,
      note: note,
      user_id: user_id,
      expression_id: expression_id,
      for_group_id: for_group_id
    })

    actioned =
      case support do
        "-1" ->
          "objected to"
        "0" ->
          "ignored"
        "1" ->
          "supported"
      end

    my_seeking_supports =
      list_my_seeking_supports(user_id)

    socket =
      socket
      |> put_flash(:info, "Successfully #{actioned} expression. Thank you!")
      |> assign(:my_seeking_supports, my_seeking_supports)
    {:noreply, socket}
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

  @impl true
  def handle_event("unsubscribe", %{"expression_id" => expression_id}, socket) do
    user_id = socket.assigns.current_user_id

    expression_subscription =
      ExpressionSubscriptions.get_expression_subscription_for_expression_and_user(expression_id, user_id)

    ExpressionSubscriptions.delete_expression_subscription(expression_subscription)

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
      |> put_flash(:info, "Successfully unsubscribed from expression.")
      |> assign(:fully_supported_expressions, fully_supported_expressions)
      |> assign(:my_subscriptions, my_subscriptions)
      |> assign(:my_expressions, my_expressions)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:expression_supported, expression}, socket) do
    #
    # If the expression is in my expressions or my seeking supports, update. otherwise
    # it doesn't concern this user
    #
    if Enum.any?(socket.assigns.my_expressions, & &1.id == expression.id) or
       Enum.any?(socket.assigns.my_seeking_supports, & &1.expression.id == expression.id) do

      user_id = socket.assigns.current_user_id

      ignored_expressions =
        list_ignored_expressions(user_id)

      my_expressions =
        list_my_expressions(user_id)
        |> filter_members_of(ignored_expressions)

      my_seeking_supports =
        list_my_seeking_supports(user_id)

      socket =
        socket
        |> assign(:my_expressions, my_expressions)
        |> assign(:my_seeking_supports, my_seeking_supports)
        |> assign(:ignored_expressions, ignored_expressions)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:sortition_created, _expression}, socket) do
    #
    # A sortition was created. Maybe I'm in it?
    # TODO: do the more efficient filtering expression, don't hit the DB
    #

    my_seeking_supports =
      list_my_seeking_supports(socket.assigns.current_user_id)

    socket =
      socket
      |> assign(my_seeking_supports: my_seeking_supports)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:expression_fully_supported, _expression}, socket) do
    user_id = socket.assigns.current_user_id

    #
    # An expression was fully supported. Remove it from the seeking_supports list
    # TODO: do the more efficient filtering expression, don't hit the DB
    # TODO: maybe the expression was fully supported for a group_id I'm not even
    # subscribed to!
    #

    my_seeking_supports =
      list_my_seeking_supports(user_id)

    ignored_expressions =
      list_ignored_expressions(user_id)

    my_subscriptions =
      list_my_subscriptions(user_id)

    fully_supported_expressions =
      list_fully_supported_expressions(user_id)
      |> filter_members_of(ignored_expressions)
      |> filter_members_of(my_subscriptions)

    socket =
      socket
      |> assign(my_seeking_supports: my_seeking_supports)
      |> assign(fully_supported_expressions: fully_supported_expressions)
    {:noreply, socket}
  end

  defp list_my_seeking_supports(user_id) do
    SeekingSupports.list_support_sought_for_user(user_id)
    |> Enum.map(fn ss ->

      expression =
        Expressions.get_expression!(ss.expression_id)
        |> Expression.annotate_with_group_data()
        |> Expression.annotate_with_linked_expressions()

      group =
        if is_nil(ss.for_group_id) do
          %{id: nil, title: "everyone"}
        else
          Expressions.get_expression!(ss.for_group_id)
        end

      %{
        expression: expression,
        group: group
      }
    end)
  end

  defp list_ignored_expressions(user_id) do
    Expressions.list_ignored_expressions(user_id)
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
  end

  defp list_fully_supported_expressions(user_id) do
    Expressions.list_fully_supported_expressions(user_id)
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
    |> Expression.annotate_with_fully_supporteds(user_id)
  end

  defp list_my_subscriptions(user_id) do
    Expressions.list_subscribed_expressions_for_user(user_id)
    |> Expression.annotate_with_supports()
    |> Expression.annotate_with_group_data()
    |> Expression.annotate_with_linked_expressions()
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

