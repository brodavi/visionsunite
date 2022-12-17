defmodule VisionsUniteWeb.PageController do
  use VisionsUniteWeb, :controller

  alias VisionsUnite.SeekingSupports

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def about(conn, _params) do
    render(conn, "about.html", group_size: 0, changeset: :group_size, sortition_size: nil)
  end

  def update_about(conn, %{"group_size" => %{"group_size" => group_size}}) do
    {group_size, ""} = Integer.parse(group_size)
    sortition_size = SeekingSupports.calculate_sortition_size(group_size)
    render(conn, "about.html", group_size: group_size, changeset: :group_size, sortition_size: sortition_size)
  end
end
