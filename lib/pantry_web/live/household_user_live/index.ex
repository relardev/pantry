defmodule PantryWeb.HouseholdUserLive.Index do
  use PantryWeb, :live_view

  alias Pantry.House
  alias Pantry.House.HouseholdUser

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :households_users, House.list_households_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Household user")
    |> assign(:household_user, House.get_household_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Household user")
    |> assign(:household_user, %HouseholdUser{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Households users")
    |> assign(:household_user, nil)
  end

  @impl true
  def handle_info({PantryWeb.HouseholdUserLive.FormComponent, {:saved, household_user}}, socket) do
    {:noreply, stream_insert(socket, :households_users, household_user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    household_user = House.get_household_user!(id)
    {:ok, _} = House.delete_household_user(household_user)

    {:noreply, stream_delete(socket, :households_users, household_user)}
  end
end
