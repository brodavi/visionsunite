defmodule VisionsUniteWeb.UserSessionPlug do
  import Plug.Conn
  use VisionsUniteWeb, :controller

  def init(options), do: options

  def call(conn, _opts) do
    if !is_nil(conn.assigns.current_user) do
      conn
      |> put_session(:current_user_id, conn.assigns.current_user.id)
    else
      redirect(conn, to: "/")
    end
  end
end
