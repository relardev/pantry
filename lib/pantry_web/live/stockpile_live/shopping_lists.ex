defmodule PantryWeb.StockpileLive.ShoppingLists do
  use PantryWeb, :live_component

  alias Pantry.House.ShoppingList

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(shopping_lists: assigns.shopping_lists)
     |> assign(household_id: assigns.household_id)
     |> assign(item_types: assigns.item_types)
     |> assign(lists: assigns.lists)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= for list <- @shopping_lists do %>
        <div>
          <.link phx-click="delete" phx-target={@myself} phx-value-id={list.id}>(Delete)</.link>
          <%= list.name %>
        </div>
      <% end %>
      <div>
        <.link phx-click="new" phx-target={@myself}>New Shopping List </.link>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("new", _value, socket) do
    Pantry.Stockpile.Household.Server.create_shopping_list(socket.assigns.household_id)

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Pantry.Stockpile.Household.Server.delete_shopping_list(socket.assigns.household_id, id)

    {:noreply, socket}
  end
end
