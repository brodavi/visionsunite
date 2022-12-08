defmodule VisionsUniteWeb.PageController do
  use VisionsUniteWeb, :controller

  def index(conn, _params) do
    if is_nil(conn.assigns.current_user) do
      render(conn, "index.html")
    else
      redirect(conn, to: "/expressions_seeking_my_support")
    end
  end
end

