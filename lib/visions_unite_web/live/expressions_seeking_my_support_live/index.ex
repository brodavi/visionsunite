defmodule VisionsUniteWeb.ExpressionsSeekingMySupportLive.Index do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Supports
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

    my_seeking_supports = list_my_seeking_supports(user_id)

    fully_supported_groupings = list_fully_supported_groupings(user_id)

    socket =
      socket
      |> assign(:current_user_id, user_id)
      |> assign(:my_seeking_supports, my_seeking_supports)
      |> assign(:fully_supported_groupings, fully_supported_groupings)

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
  def handle_event(
        "my_support",
        %{
          "support_form" => %{
            "expression_id" => expression_id,
            "support" => support,
            "note" => note,
            "for_group_id" => for_group_id
          }
        },
        socket
      ) do
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

    my_seeking_supports = list_my_seeking_supports(user_id)

    fully_supported_groupings = list_fully_supported_groupings(user_id)

    socket =
      socket
      |> put_flash(:info, "Successfully #{actioned} expression. Thank you!")
      |> assign(:my_seeking_supports, my_seeking_supports)
      |> assign(:fully_supported_groupings, fully_supported_groupings)

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

  defp list_fully_supported_groupings(user_id) do
    seeking_supports = list_my_seeking_supports(user_id)

    seeking_supports
    |> Enum.group_by(& &1.group)
  end
end

