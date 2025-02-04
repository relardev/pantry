defmodule PantryWeb.StockpileLive.ShoppingLists do
  use PantryWeb, :live_component

  alias Pantry.House.ShoppingList

  @impl true
  def update(assigns, socket) do
    lists = prepare_for_front(assigns.shopping_lists, assigns.item_types)

    {:ok,
     socket
     |> assign(shopping_lists: lists)
     |> assign(household_id: assigns.household_id)
     |> assign(item_types: assigns.item_types)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= for {list, list_form} <- @shopping_lists do %>
        <div>
          <.form
            for={list_form}
            phx-submit="save"
            phx-change="save"
            phx-debounce="200"
            phx-target={@myself}
            phx-value-id={list.id}
          >
            <div class="flex space-x-2 items-center">
              <.input type="text" name="name" value={list.name} placeholder="Shopping List name" />
              <.link phx-click="delete" phx-target={@myself} phx-value-id={list.id}>
                <.icon name="hero-x-mark" class="w-6 h-6" />
              </.link>
            </div>

            <.inputs_for :let={item_form} field={list_form[:items]}>
              <div class="flex space-x-2 items-center">
                <.input type="text" field={item_form[:quantity]} placeholder="quantity" />
              </div>
            </.inputs_for>
          </.form>
        </div>
      <% end %>
      <div>
        <.link phx-click="new" phx-target={@myself}>(+) New Shopping List </.link>
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

  def handle_event("save", %{"_target" => ["name"], "id" => id, "name" => name}, socket) do
    Pantry.Stockpile.Household.Server.update_shopping_list(
      socket.assigns.household_id,
      id,
      %{"name" => name, "household_id" => socket.assigns.household_id}
    )

    {:noreply, socket}
  end

  def prepare_for_front(lists, item_types) do
    lists
    |> Enum.map(&prepare_list_for_front(&1, item_types))
  end

  def prepare_list_for_front(list, _item_types) do
    {list, to_form(ShoppingList.changeset(list, %{}))}
  end
end
