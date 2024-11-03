defmodule PantryWeb.HouseholdLive.FormComponent do
  use PantryWeb, :live_component

  alias Pantry.House

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage household records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="household-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Household</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{household: household} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(House.change_household(household))
     end)}
  end

  @impl true
  def handle_event("validate", %{"household" => household_params}, socket) do
    changeset = House.change_household(socket.assigns.household, household_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"household" => household_params}, socket) do
    save_household(socket, socket.assigns.action, household_params)
  end

  defp save_household(socket, :edit, household_params) do
    case House.update_household_for_user(
           socket.assigns.household,
           socket.assigns.user_id,
           household_params
         ) do
      {:ok, household} ->
        notify_parent({:saved, household})

        {:noreply,
         socket
         |> put_flash(:info, "Household updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_household(socket, :new, household_params) do
    case House.create_household_for_user(household_params, socket.assigns.user_id) do
      {:ok, household} ->
        notify_parent({:saved, household})

        {:noreply,
         socket
         |> put_flash(:info, "Household created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
