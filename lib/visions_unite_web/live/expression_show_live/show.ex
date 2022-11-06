defmodule VisionsUniteWeb.ExpressionShowLive.Show do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Supports
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUniteWeb.ExpressionComponent
  alias VisionsUniteWeb.NavComponent

  @impl true
  def mount(params, session, socket) do
    IO.puts "got params: #{inspect params}"

    user_id = session["current_user_id"]

    expression =
      Expressions.get_expression!(params["id"])
      |> Expression.annotate_with_supports()
      |> Expression.annotate_with_group_data()
      |> Expression.annotate_with_linked_expressions()
      |> Expression.annotate_with_fully_supporteds(user_id)
      |> Expression.annotate_with_seeking_support(user_id)
      |> Expression.annotate_subscribed(user_id)

    socket =
      socket
      |> assign(:current_user_id, user_id)
      |> assign(:expression, expression)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, params) do
    socket
    |> assign(:page_title, "Showing Expression")
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
end

