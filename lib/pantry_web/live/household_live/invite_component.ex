defmodule PantryWeb.HouseholdLive.InviteComponent do
  use PantryWeb, :live_component

  alias Pantry.House

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Invite person to your household</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="invite-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="invite"
      >
        <.input field={@form[:email]} type="text" label="Email" />
        <:actions>
          <.button phx-disable-with="Sending...">Send Invite</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{"email" => ""})
     end)}
  end

  @impl true
  def handle_event("validate", %{"email" => _email} = form_data, socket) do
    # TODO, add validation
    {:noreply, assign(socket, form: to_form(form_data, action: :validate))}
  end

  def handle_event("invite", %{"email" => email}, socket) do
    case House.create_invite(email, socket.assigns.user_id, socket.assigns.household_id,
           preload: [:sender_user, :household]
         ) do
      {:ok, invite} ->
        PantryWeb.InviteLive.Index.notify_new_invite(email, invite)
        success(socket)

      {:error, :user_not_found} ->
        success(socket)

      {:error, :already_member} ->
        {:noreply,
         socket
         |> put_flash(:info, "User is a member already")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _chageset} ->
        success(socket)
    end
  end

  defp success(socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Invite sent if email is valid")
     |> push_patch(to: socket.assigns.patch)}
  end
end
