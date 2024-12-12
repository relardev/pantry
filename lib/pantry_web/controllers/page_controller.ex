defmodule PantryWeb.PageController do
  use PantryWeb, :controller

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        # The home page is often custom made,
        # so skip the default app layout.
        render(conn, :home, layout: false)

      _ ->
        redirect(conn, to: ~p"/app")
    end
  end
end
