defmodule VisionsUniteWeb.SupportController do
  use VisionsUniteWeb, :controller

  alias VisionsUnite.Supports
  alias VisionsUnite.Supports.Support

  def index(conn, _params) do
    support = Supports.list_support()
    render(conn, "index.html", support: support)
  end

  def new(conn, _params) do
    changeset = Supports.change_support(%Support{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"support" => support_params}) do
    case Supports.create_support(support_params) do
      {:ok, support} ->
        conn
        |> put_flash(:info, "Support created successfully.")
        |> redirect(to: Routes.support_path(conn, :show, support))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    support = Supports.get_support!(id)
    render(conn, "show.html", support: support)
  end

  def edit(conn, %{"id" => id}) do
    support = Supports.get_support!(id)
    changeset = Supports.change_support(support)
    render(conn, "edit.html", support: support, changeset: changeset)
  end

  def update(conn, %{"id" => id, "support" => support_params}) do
    support = Supports.get_support!(id)

    case Supports.update_support(support, support_params) do
      {:ok, support} ->
        conn
        |> put_flash(:info, "Support updated successfully.")
        |> redirect(to: Routes.support_path(conn, :show, support))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", support: support, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    support = Supports.get_support!(id)
    {:ok, _support} = Supports.delete_support(support)

    conn
    |> put_flash(:info, "Support deleted successfully.")
    |> redirect(to: Routes.support_path(conn, :index))
  end
end
