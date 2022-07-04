defmodule VisionsUniteWeb.ExpressionLiveTest do
  use VisionsUniteWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisionsUnite.ExpressionsFixtures

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}

  defp create_expression(_) do
    expression = expression_fixture()
    %{expression: expression}
  end

  describe "Index" do
    setup [:create_expression]

    test "lists all expressions", %{conn: conn, expression: expression} do
      {:ok, _index_live, html} = live(conn, Routes.expression_index_path(conn, :index))

      assert html =~ "Listing Expressions"
      assert html =~ expression.body
    end

    test "saves new expression", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.expression_index_path(conn, :index))

      assert index_live |> element("a", "New Expression") |> render_click() =~
               "New Expression"

      assert_patch(index_live, Routes.expression_index_path(conn, :new))

      assert index_live
             |> form("#expression-form", expression: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#expression-form", expression: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.expression_index_path(conn, :index))

      assert html =~ "Expression created successfully"
      assert html =~ "some body"
    end

    test "updates expression in listing", %{conn: conn, expression: expression} do
      {:ok, index_live, _html} = live(conn, Routes.expression_index_path(conn, :index))

      assert index_live |> element("#expression-#{expression.id} a", "Edit") |> render_click() =~
               "Edit Expression"

      assert_patch(index_live, Routes.expression_index_path(conn, :edit, expression))

      assert index_live
             |> form("#expression-form", expression: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#expression-form", expression: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.expression_index_path(conn, :index))

      assert html =~ "Expression updated successfully"
      assert html =~ "some updated body"
    end

    test "deletes expression in listing", %{conn: conn, expression: expression} do
      {:ok, index_live, _html} = live(conn, Routes.expression_index_path(conn, :index))

      assert index_live |> element("#expression-#{expression.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#expression-#{expression.id}")
    end
  end

  describe "Show" do
    setup [:create_expression]

    test "displays expression", %{conn: conn, expression: expression} do
      {:ok, _show_live, html} = live(conn, Routes.expression_show_path(conn, :show, expression))

      assert html =~ "Show Expression"
      assert html =~ expression.body
    end

    test "updates expression within modal", %{conn: conn, expression: expression} do
      {:ok, show_live, _html} = live(conn, Routes.expression_show_path(conn, :show, expression))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Expression"

      assert_patch(show_live, Routes.expression_show_path(conn, :edit, expression))

      assert show_live
             |> form("#expression-form", expression: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#expression-form", expression: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.expression_show_path(conn, :show, expression))

      assert html =~ "Expression updated successfully"
      assert html =~ "some updated body"
    end
  end
end
