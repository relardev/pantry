defmodule PantryWeb.HouseholdLive.Show do
  use PantryWeb, :live_view

  alias Pantry.House

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:household, House.get_household!(id, socket.assigns.current_user.id))}
  end

  defp page_title(:show), do: "Show Household"
  defp page_title(:edit), do: "Edit Household"
end
