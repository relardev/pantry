defmodule PantryWeb.HouseholdUserLive.FormComponent do
  use PantryWeb, :live_component

  alias Pantry.House

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage household_user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="household_user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button phx-disable-with="Saving...">Save Household user</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{household_user: household_user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(House.change_household_user(household_user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"household_user" => household_user_params}, socket) do
    changeset = House.change_household_user(socket.assigns.household_user, household_user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"household_user" => household_user_params}, socket) do
    save_household_user(socket, socket.assigns.action, household_user_params)
  end

  defp save_household_user(socket, :edit, household_user_params) do
    case House.update_household_user(socket.assigns.household_user, household_user_params) do
      {:ok, household_user} ->
        notify_parent({:saved, household_user})

        {:noreply,
         socket
         |> put_flash(:info, "Household user updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_household_user(socket, :new, household_user_params) do
    case House.create_household_user(household_user_params) do
      {:ok, household_user} ->
        notify_parent({:saved, household_user})

        {:noreply,
         socket
         |> put_flash(:info, "Household user created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
