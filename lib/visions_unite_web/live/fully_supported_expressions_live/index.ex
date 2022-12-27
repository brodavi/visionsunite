defmodule VisionsUniteWeb.FullySupportedExpressionsLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Expressions
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUniteWeb.ExpressionComponent
  alias VisionsUniteWeb.NavComponent

  @impl true
  def mount(_params, session, socket) do
    user_id = session["current_user_id"]

    socket =
      socket
      |> assign(:current_user_id, user_id)

    seeking_support_from_user =
      SeekingSupports.list_support_sought_for_user(user_id)

    if Enum.count(seeking_support_from_user) !== 0 do
      socket =
        socket
        |> redirect(to: "/vote")
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index_important_groups, _params) do
    groups = list_vetted_groups()

    socket
    |> assign(:page_title, "Listing Important Groups")
    |> assign(:live_action, :important_groups)
    |> assign(:groups, groups)
    |> assign(:messages, [])
  end

  defp apply_action(socket, :my_subscribed_groups, _params) do
    groups = list_vetted_groups_for_user(socket.assigns.current_user_id)

    socket
    |> assign(:page_title, "Listing Subscribed Groups")
    |> assign(:live_action, :my_subscribed_groups)
    |> assign(:groups, groups)
    |> assign(:messages, [])
  end

  defp apply_action(socket, :index_important_messages, _params) do
    important_messages = list_supported_messages(socket.assigns.current_user_id)

    socket
    |> assign(:page_title, "Listing Important Messages")
    |> assign(:live_action, :important_messages)
    |> assign(:groups, [])
    |> assign(:messages, important_messages)
  end

  defp apply_action(socket, :my_subscribed_messages, _params) do
    messages = list_supported_messages_for_user(socket.assigns.current_user_id)

    socket
    |> assign(:page_title, "Listing Subscribed Messages")
    |> assign(:live_action, :my_subscribed_messages)
    |> assign(:groups, [])
    |> assign(:messages, messages)
  end

  defp list_vetted_groups() do
    Expressions.list_vetted_groups()
  end

  defp list_vetted_groups_for_user(user_id) do
    Expressions.list_vetted_groups_for_user(user_id)
  end

  defp list_supported_messages(user_id) do
    Expressions.list_supported_messages()
    |> Expression.annotate_with_fully_supporteds(user_id)
  end

  defp list_supported_messages_for_user(user_id) do
    Expressions.list_supported_messages_for_user(user_id)
    |> Expression.annotate_with_fully_supporteds(user_id)
  end
end
