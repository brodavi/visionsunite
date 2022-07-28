defmodule VisionsUniteWeb.ExpressionLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Accounts
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Supports
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUniteWeb.ExpressionComponent

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      VisionsUniteWeb.SharedPubSub.subscribe("sortitions")
      VisionsUniteWeb.SharedPubSub.subscribe("support")
      VisionsUniteWeb.SharedPubSub.subscribe("supported_expressions")
    end

    user_id = session["current_user_id"]

    socket =
      socket
      |> assign(:audience, "everyone")
      |> assign(:current_user_id, user_id)
      |> assign(:my_expressions, list_my_expressions(user_id))
      |> assign(:my_subscriptions, list_my_subscriptions(user_id))
      |> assign(:fully_supported_expressions, list_fully_supported_expressions(user_id))
      |> assign(:seeking_support, list_expressions_seeking_my_support(user_id))
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Expression")
    |> assign(:expression, Expressions.get_expression!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Expression")
    |> assign(:expression, %Expression{links: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Expressions")
    |> assign(:expression, nil)
  end

  @impl true
  def handle_event("my_support", %{"expression_id" => expression_id, "support" => support}, socket) do
    Supports.create_support(%{ expression_id: expression_id, user_id: socket.assigns.current_user_id, support: support })

    actioned =
      case support do
        "-1" ->
          "objected to"
        "0" ->
          "ignored"
        "1" ->
          "supported"
      end

    socket =
      socket
      |> put_flash(:info, "Successfully #{actioned} expression. Thank you!")
      |> assign(:seeking_support, list_expressions_seeking_my_support(socket.assigns.current_user_id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("subscribe", %{"expression_id" => expression_id}, socket) do
    ExpressionSubscriptions.create_expression_subscription(%{ expression_id: expression_id, user_id: socket.assigns.current_user_id })

    user_id = socket.assigns.current_user_id

    socket =
      socket
      |> put_flash(:info, "Successfully subscribed to expression. Thank you!")
      |> assign(:my_subscriptions, list_my_subscriptions(user_id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("unsubscribe", %{"expression_id" => expression_id}, socket) do
    user_id = socket.assigns.current_user_id

    expression_subscription =
      ExpressionSubscriptions.get_expression_subscription_for_expression_and_user(expression_id, user_id)

    ExpressionSubscriptions.delete_expression_subscription(expression_subscription)

    socket =
      socket
      |> put_flash(:info, "Successfully unsubscribed from expression.")
      |> assign(:my_subscriptions, list_my_subscriptions(user_id))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:expression_supported, expression}, socket) do
    if Enum.any?(socket.assigns.my_expressions, & &1.id == expression.id) do
      socket =
        socket
        |> assign(:my_expressions, list_my_expressions(socket.assigns.current_user_id))
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:sortition_created, expression}, socket) do
    sortition = SeekingSupports.list_support_sought_for_expression(expression)

    expression =
      annotate_with_supports_and_links(expression)

    if Enum.find(sortition, & &1.user_id == socket.assigns.current_user_id) do
      socket =
        socket
        |> assign(seeking_support: [expression | socket.assigns.seeking_support])
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:expression_fully_supported, expression}, socket) do
    # An expression was fully supported. Remove it from the seeking_support list
    seeking_support =
      socket.assigns.seeking_support
      |> Enum.filter(fn expression_seeking_support ->
        expression_seeking_support.id != expression.id
      end)

    socket =
      socket
      |> assign(seeking_support: seeking_support)
      |> assign(fully_supported_expressions: [expression |> annotate_with_supports_and_links | socket.assigns.fully_supported_expressions])
    {:noreply, socket}
  end

  defp list_expressions_seeking_my_support(id) do
    Expressions.list_expressions_seeking_support_from_user(id)
    |> annotate_with_supports_and_links()
  end

  defp list_fully_supported_expressions(id) do
    Expressions.list_fully_supported_expressions(id)
    |> annotate_with_supports_and_links()
  end

  defp list_my_subscriptions(id) do
    Expressions.list_subscribed_expressions_for_user(id)
    |> annotate_with_supports_and_links()
  end

  defp list_my_expressions(id) do
    Expressions.list_expressions_for_user(id)
    |> annotate_with_supports_and_links()
    |> annotate_with_quorum_and_group_count()
  end

  #
  # This function annotates a list of expressions with each expression's quorum
  # and group count. If the expression is a root expression, then the group count
  # is the list of all the users in the system. If the expression is linked to
  # other expressions, then there are multiple group counts per linked expression.
  #

  defp annotate_with_quorum_and_group_count(expressions) do
    expressions
    |> Enum.map(fn expression ->

      # quorums is this list of quorums for this expression (quorums of all linked expressions)
      # if the expression has no links, or only one link, the list is length 1

      quorums =
        SeekingSupports.get_quorum_nums_for_expression(expression)

      # group_counts is the list of subscriptions for this expression (group counts of all linked expressions)
      # if the expression has no links, or only one link, the list is length 1

      group_counts =
        ExpressionSubscriptions.list_expression_subscriptions_for_expression(expression.id)

      Map.merge(expression, %{
        quorums: quorums,
        group_counts: group_counts
      })
    end)
  end

  defp annotate_with_supports_and_links(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_supports_and_links(expression)
    end)
  end

  defp annotate_with_supports_and_links(expression) when is_map(expression) do
    Map.merge(expression, %{
      supports: Supports.list_supports_for_expression(expression),
      links: Enum.map(expression.links, & &1.title),
    })
  end
end

