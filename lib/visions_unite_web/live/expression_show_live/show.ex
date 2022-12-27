defmodule VisionsUniteWeb.ExpressionShowLive.Show do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Accounts
  alias VisionsUnite.Supports
  alias VisionsUnite.FullySupporteds
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.ExpressionLinkages
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUniteWeb.ExpressionComponent
  alias VisionsUniteWeb.NavComponent

  @impl true
  def mount(params, session, socket) do
    user_id = session["current_user_id"]
    expression_id = params["id"]

    socket =
      socket
      |> assign(:view_all, :false)
      |> update_expression(expression_id, user_id)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Showing Expression")
  end

  defp apply_action(socket, :new, %{"id" => linked_expression_id}) do
    linked_expression_title = Expressions.get_expression!(linked_expression_id).title

    socket
    |> assign(:page_title, "New Message")
    |> assign(:new_expression, %Expression{})
    |> assign(:linked_expression_id, linked_expression_id)
    |> assign(:linked_expression_title, linked_expression_title)
  end

  @impl true
  def handle_event("view_all_toggle", _params, socket) do
    socket =
      socket
      |> assign(:view_all, !socket.assigns.view_all)
      |> update_expression(socket.assigns.expression.id, socket.assigns.current_user_id)

    {:noreply, socket}
  end

  def handle_event("set_follow", %{"expression_id" => expression_id, "follow" => follow}, socket) do

    user_id = socket.assigns.current_user_id

    existing_subscription =
      ExpressionSubscriptions.get_expression_subscription_for_expression_and_user(
        expression_id,
        user_id
      )

    existing_mute =
      ExpressionSubscriptions.get_expression_muting_for_expression_and_user(
        expression_id,
        user_id
      )

    case {existing_subscription, existing_mute} do
      {nil, nil} ->
        result =
          ExpressionSubscriptions.create_expression_subscription(%{
            expression_id: expression_id,
            user_id: user_id,
            subscribe: follow
          })

      {existing_subscription, nil} ->
        ExpressionSubscriptions.update_expression_subscription(
          existing_subscription,
          %{
            subscribe: follow
          }
        )

      {nil, existing_mute} ->
        ExpressionSubscriptions.update_expression_subscription(
          existing_mute,
          %{
            subscribe: follow
          }
        )
    end

    actioned =
      case follow do
        "true" ->
          "followed"

        "false" ->
          "unfollowed"
      end

    socket =
      socket
      |> put_flash(:info, "Successfully #{actioned}.")

    socket = update_expression(socket, expression_id, user_id)

    {:noreply, socket}
  end

  defp update_expression(socket, expression_id, user_id) do
    expression =
      Expressions.get_expression!(expression_id)
      |> Expression.annotate_with_supports()
      |> Expression.annotate_with_group_data()
      |> Expression.annotate_with_linked_expressions()
      |> Expression.annotate_with_fully_supporteds(user_id)
      |> Expression.annotate_with_seeking_support(user_id)
      |> Expression.annotate_subscribed(user_id)

    supports = Supports.list_all_supports_for_expression(expression)

    seeking_supports = SeekingSupports.list_support_sought_for_expression(expression)

    linkages = ExpressionLinkages.list_expression_linkages_for_expression(expression.id)

    subscriptions =
      ExpressionSubscriptions.list_expression_subscriptions_for_expression(expression)

    fully_supporteds = FullySupporteds.list_fully_supporteds_for_expression(expression.id)

    children =
      case socket.assigns.view_all do
        :true ->
          ExpressionLinkages.list_children_for_expression(expression.id)
        :false ->
          ExpressionLinkages.list_supported_children_for_expression(expression.id)
      end

    children =
      children
      |> Enum.map(& Expressions.get_expression!(&1.expression_id))
      |> Expression.annotate_with_fully_supporteds(user_id)

    current_user = Accounts.get_user!(user_id)

    socket
    |> assign(:current_user_id, user_id)
    |> assign(:current_user, current_user)
    |> assign(:expression, expression)
    |> assign(:seeking_supports, seeking_supports)
    |> assign(:supports, supports)
    |> assign(:linkages, linkages)
    |> assign(:subscriptions, subscriptions)
    |> assign(:fully_supporteds, fully_supporteds)
    |> assign(:children, children)
  end
end
