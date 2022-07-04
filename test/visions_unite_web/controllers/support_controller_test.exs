defmodule VisionsUniteWeb.SupportControllerTest do
  use VisionsUniteWeb.ConnCase

  import VisionsUnite.SupportsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  describe "index" do
    test "lists all support", %{conn: conn} do
      conn = get(conn, Routes.support_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Supports"
    end
  end

  describe "new support" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.support_path(conn, :new))
      assert html_response(conn, 200) =~ "New Support"
    end
  end

  describe "create support" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.support_path(conn, :create), support: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.support_path(conn, :show, id)

      conn = get(conn, Routes.support_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Support"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.support_path(conn, :create), support: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Support"
    end
  end

  describe "edit support" do
    setup [:create_support]

    test "renders form for editing chosen support", %{conn: conn, support: support} do
      conn = get(conn, Routes.support_path(conn, :edit, support))
      assert html_response(conn, 200) =~ "Edit Support"
    end
  end

  describe "update support" do
    setup [:create_support]

    test "redirects when data is valid", %{conn: conn, support: support} do
      conn = put(conn, Routes.support_path(conn, :update, support), support: @update_attrs)
      assert redirected_to(conn) == Routes.support_path(conn, :show, support)

      conn = get(conn, Routes.support_path(conn, :show, support))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, support: support} do
      conn = put(conn, Routes.support_path(conn, :update, support), support: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Support"
    end
  end

  describe "delete support" do
    setup [:create_support]

    test "deletes chosen support", %{conn: conn, support: support} do
      conn = delete(conn, Routes.support_path(conn, :delete, support))
      assert redirected_to(conn) == Routes.support_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.support_path(conn, :show, support))
      end
    end
  end

  defp create_support(_) do
    support = support_fixture()
    %{support: support}
  end
end
