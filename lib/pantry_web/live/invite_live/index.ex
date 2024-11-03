defmodule PantryWeb.InviteLive.Index do
  use PantryWeb, :live_view

  alias Pantry.House

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :invites, House.list_invites(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invite = House.get_invite!(id, socket.assigns.current_user.id)
    {:ok, _} = House.delete_invite(invite)

    {:noreply, stream_delete(socket, :invites, invite)}
  end
end
