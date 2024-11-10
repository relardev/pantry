defmodule PantryWeb.HouseholdLive.Index do
  use PantryWeb, :live_view

  alias Pantry.House
  alias Pantry.House.Household

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :households, House.list_households(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Household")
    |> assign(:household, House.get_household!(id, socket.assigns.current_user.id))
  end

  defp apply_action(socket, :invite, %{"id" => id}) do
    socket
    |> assign(:page_title, "Invite to Household")
    |> assign(:household, House.get_household!(id, socket.assigns.current_user.id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Household")
    |> assign(:household, %Household{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Households")
    |> assign(:household, nil)
  end

  @impl true
  def handle_info({PantryWeb.HouseholdLive.FormComponent, {:saved, household}}, socket) do
    {:noreply, stream_insert(socket, :households, household)}
  end

  @impl true
  def handle_event("leave", %{"id" => id}, socket) do
    household_user = House.get_household_user(id, socket.assigns.current_user.id)
    House.delete_household_user(household_user)
    Pantry.Stockpile.Household.Server.reload(id)
    {:noreply, stream_delete(socket, :households, %{id: id})}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    household = House.get_household!(id, socket.assigns.current_user.id)
    {:ok, _} = House.delete_household(household)

    {:noreply, stream_delete(socket, :households, household)}
  end

  def handle_event("activate", %{"id" => id}, socket) do
    Pantry.Accounts.activate_household(socket.assigns.current_user, id)

    {:noreply, push_navigate(socket, to: ~p"/")}
  end
end
