defmodule VisionsUniteWeb.ExpressionLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Accounts
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
      |> assign(:my_seeking_supports, list_my_seeking_supports(user_id))
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
  def handle_event("my_support", %{"support_form" => %{
    "expression_id" => expression_id,
    "support" => support,
    "note" => note,
    "for_group_id" => for_group_id
  }}, socket) do

    Supports.create_support(%{
      expression_id: expression_id,
      for_group_id: for_group_id,
      user_id: socket.assigns.current_user_id,
      support: support,
      note: note
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

    socket =
      socket
      |> put_flash(:info, "Successfully #{actioned} expression. Thank you!")
      |> assign(:my_seeking_supports, list_my_seeking_supports(socket.assigns.current_user_id))
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
      my_expressions = list_my_expressions(socket.assigns.current_user_id)

      socket =
        socket
        |> assign(:my_expressions, my_expressions)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:sortition_created, expression}, socket) do
    my_seeking_supports = list_my_seeking_supports(socket.assigns.current_user_id)

    socket =
      socket
      |> assign(my_seeking_supports: my_seeking_supports)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:expression_fully_supported, expression}, socket) do
    # An expression was fully supported. Remove it from the seeking_supports list
    # TODO: do the more efficient filtering expression, don't hit the DB
    my_seeking_supports = list_my_seeking_supports(socket.assigns.current_user_id)
    fully_supported_expressions = list_fully_supported_expressions(socket.assigns.current_user_id)

    socket =
      socket
      |> assign(my_seeking_supports: my_seeking_supports)
      |> assign(fully_supported_expressions: fully_supported_expressions)
    {:noreply, socket}
  end

  defp list_my_seeking_supports(user_id) do
    my_seeking_supports =
    SeekingSupports.list_support_sought_for_user(user_id)
    |> Enum.map(fn ss ->

      expression =
        Expressions.get_expression!(ss.expression_id)
        |> annotate_with_support()
        |> annotate_with_group_data()
        |> annotate_links()

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

    my_seeking_supports
  end

  defp list_fully_supported_expressions(id) do
    Expressions.list_fully_supported_expressions(id)
    |> annotate_with_support()
    |> annotate_with_group_data()
    |> annotate_links()
  end

  defp list_my_subscriptions(id) do
    Expressions.list_subscribed_expressions_for_user(id)
    |> annotate_with_support()
    |> annotate_with_group_data()
    |> annotate_links() end

  defp list_my_expressions(id) do
    Expressions.list_expressions_for_user(id)
    |> annotate_with_support()
    |> annotate_with_group_data()
    |> annotate_links()
    |> annotate_with_notes()
  end

  defp annotate_with_notes(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_notes(expression)
    end)
  end

  defp annotate_with_notes(expression) when is_map(expression) do
    notes =
      Supports.list_supports_for_expression(expression)
      |> Enum.map(& &1.note)

    Map.merge(expression, %{
      notes: notes
    })
  end

  defp annotate_links(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_links(expression)
    end)
  end

  defp annotate_links(expression) when is_map(expression) do
    annotated_links =
      expression.links
      |> annotate_with_support()
      |> annotate_with_group_data()

    Map.merge(expression, %{
      links: annotated_links
    })
  end

  defp annotate_with_group_data(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_group_data(expression)
    end)
  end

  defp annotate_with_group_data(expression) when is_map(expression) do
    subscription_count =
      ExpressionSubscriptions.count_expression_subscriptions_for_expression(expression)

    sortition_count =
      SeekingSupports.calculate_sortition_size(subscription_count)

    subscription_count =
      if subscription_count == 1 do
        # This only has 1 subscriber... the author... so it is a root expression
        Accounts.count_users()
      else
        subscription_count
      end

    sortition_count =
      if sortition_count == 1 do
        # This only has a sortition count of 1 ... the author... so it is a root expression
        SeekingSupports.calculate_sortition_size(Accounts.count_users())
      else
        sortition_count
      end

    Map.merge(expression, %{
      sortition_count: sortition_count,
      quorum_count: Kernel.round(sortition_count * 0.51),
      subscription_count: subscription_count
    })
  end

  defp annotate_with_support(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_support(expression)
    end)
  end

  defp annotate_with_support(expression) when is_map(expression) do
    Map.merge(expression, %{
      support: Supports.count_support_for_expression(expression)
    })
  end
end

