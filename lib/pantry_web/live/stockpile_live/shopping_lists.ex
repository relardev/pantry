defmodule PantryWeb.StockpileLive.ShoppingLists do
  use PantryWeb, :live_component

  alias Pantry.House.ShoppingList

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
     |> assign(item_types: assigns.item_types)
     |> assign(lists: assigns.lists)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>hi</div>
    """
  end
end
