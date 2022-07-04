defmodule VisionsUniteWeb.ExpressionLive.Show do
  use VisionsUniteWeb, :live_view

  alias VisionsUnite.Expressions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:expression, Expressions.get_expression!(id))}
  end

  defp page_title(:show), do: "Show Expression"
  defp page_title(:edit), do: "Edit Expression"
end
