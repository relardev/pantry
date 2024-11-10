defmodule PantryWeb.InviteLive.Index do
  use PantryWeb, :live_view

  alias Pantry.House

  def notify_new_invite(email, invite) do
    Phoenix.PubSub.broadcast(Pantry.PubSub, topic(email), {
      :new_invite,
      invite
    })
  end

  defp topic(email) do
    "invite:#{email}"
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Pantry.PubSub, topic(socket.assigns.current_user.email))
    end

    {:ok, stream(socket, :invites, House.list_invites(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invite = House.get_invite!(id, socket.assigns.current_user.id)
    {:ok, _} = House.delete_invite(invite)

    {:noreply, stream_delete(socket, :invites, invite)}
  end

  def handle_event("accept", %{"id" => id}, socket) do
    household_user = House.accept_invite!(id, socket.assigns.current_user.id)

    household = House.get_household!(household_user.household_id, socket.assigns.current_user.id)

    Pantry.Stockpile.Household.Server.reload(id)
    Pantry.Accounts.activate_household(socket.assigns.current_user, id)

    {:noreply,
     socket
     |> put_flash(:info, "Welcome to #{household.name}")
     |> push_navigate(to: ~p"/")}
  end

  @impl true
  def handle_info({:new_invite, invite}, socket) do
    {:noreply, stream_insert(socket, :invites, invite)}
  end
end
