defmodule VisionsUniteWeb.PageController do
  use VisionsUniteWeb, :controller

  alias VisionsUnite.Supports
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Expressions
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.NewNotifications
  alias VisionsUniteWeb.ExpressionComponent

  def submit_vote(conn, %{"viewed" => _}) do
    NewNotifications.list_new_notifications_for_user(conn.assigns.current_user.id)
    |> Enum.each(& NewNotifications.delete_new_notification(&1))

    seeking_supports =
      SeekingSupports.list_support_sought_for_user(conn.assigns.current_user.id)
      |> Enum.map(& Expressions.get_expression!(&1.expression_id))
      |> Expression.annotate_with_group_data()
      |> Expression.annotate_with_seeking_support(conn.assigns.current_user.id)

    new_expressions = []

    if Enum.count(seeking_supports) !== 0 do
      render(conn, "vote.html", seeking_supports: seeking_supports, new_expressions: new_expressions)
    else
      redirect(conn, to: "/")
    end
  end

  def submit_vote(conn, %{"support" => support_params}) do
    actioned =
      case support_params["support"] do
        nil ->
          {:error, "no vote"}

        "-1" ->
          "objected to"

        "1" ->
          "supported"
      end

    Supports.create_support(%{
      support: support_params["support"],
      note: support_params["note"],
      user_id: conn.assigns.current_user.id,
      expression_id: support_params["expression_id"],
      for_group_id: support_params["for_group_id"]
    })

    seeking_supports =
      SeekingSupports.list_support_sought_for_user(conn.assigns.current_user.id)
      |> Enum.map(& Expressions.get_expression!(&1.expression_id))
      |> Expression.annotate_with_group_data()
      |> Expression.annotate_with_seeking_support(conn.assigns.current_user.id)

    new_expressions =
      Expressions.list_new_expressions_for_user(conn.assigns.current_user.id)
      |> Expression.annotate_with_fully_supporteds()

    case actioned do
      {:error, "no vote"} ->
        conn =
          conn
          |> put_flash(:error, "Please select \"support\" or \"reject\" below.")

        render(conn, "vote.html", seeking_supports: seeking_supports, new_expressions: new_expressions)
      _ ->

        conn =
          conn
          |> put_flash(:info, "Successfully #{actioned} expression. Thank you!")

        if Enum.count(seeking_supports) !== 0 do
          render(conn, "vote.html", seeking_supports: seeking_supports, new_expressions: new_expressions)
        else
          redirect(conn, to: "/")
        end
    end
  end

  def vote(conn, _params) do
    seeking_supports =
      SeekingSupports.list_support_sought_for_user(conn.assigns.current_user.id)
      |> Enum.map(& Expressions.get_expression!(&1.expression_id))
      |> Expression.annotate_with_group_data()
      |> Expression.annotate_with_seeking_support(conn.assigns.current_user.id)

    new_expressions =
      Expressions.list_new_expressions_for_user(conn.assigns.current_user.id)

    render(conn, "vote.html", seeking_supports: seeking_supports, new_expressions: new_expressions)
  end

  def about(conn, _params) do
    render(conn, "about.html", group_size: 0, changeset: :group_size, sortition_size: nil)
  end

  def update_about(conn, %{"group_size" => %{"group_size" => group_size}}) do
    {group_size, ""} = Integer.parse(group_size)
    sortition_size = SeekingSupports.calculate_sortition_size(group_size)

    render(conn, "about.html",
      group_size: group_size,
      changeset: :group_size,
      sortition_size: sortition_size
    )
  end

  def save_group(conn, %{"expression" => expression_params}) do
    expression_params = Map.put(expression_params, "author_id", conn.assigns.current_user.id)
    case Expressions.create_expression_and_seek_support(expression_params) do
      {:ok, _expression} ->
        conn =
          conn
          |> put_flash(:info, "Group created successfully")

        redirect(conn, to: "/my_expressions")

      {:error, changeset} ->
        conn =
          conn
          |> put_flash(:error, "Error? changeset: #{inspect changeset}")

        redirect(conn, to: "/my_expressions", changeset: changeset)
    end
  end

  def save_message(conn, %{"expression" => expression_params}) do
    expression_params = Map.put(expression_params, "author_id", conn.assigns.current_user.id)
    linked_expressions = [expression_params["linked_expression_id"]]

    case Expressions.create_expression(expression_params, linked_expressions) do
      {:ok, _expression, _seeking_supports} ->
        conn =
          conn
          |> put_flash(:info, "Message created successfully")

        redirect(conn, to: "/my_expressions")

      {:error, changeset} ->
        conn =
          conn
          |> put_flash(:error, "Error? #{inspect changeset}")

        redirect(conn, to: "/my_expressions", changeset: changeset)
    end
  end
end
