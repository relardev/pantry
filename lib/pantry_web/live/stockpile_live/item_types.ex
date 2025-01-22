defmodule PantryWeb.StockpileLive.ItemTypes do
  use PantryWeb, :live_component

  alias Pantry.House.ItemType

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
     |> assign(items: assigns.items)
     |> assign(item_types: prepare_for_front(assigns.item_types, assigns.items, assigns.recipes))
     |> assign(recipes: assigns.recipes)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table id="items" rows={@item_types} row_id={&("item_type-" <> &1.id)}>
        <:col :let={item_type} label="Name"><%= item_type.name %></:col>
        <:col :let={item_type} label="Always available">
          <.form
            for={item_type.always_available_form}
            id={"always-available-form-" <> item_type.id}
            phx-target={@myself}
            phx-submit={"change-" <> item_type.id}
            phx-change={"change-" <> item_type.id}
          >
            <.input
              type="checkbox"
              name="always_available"
              id={"always-available-" <> item_type.id}
              value={item_type.always_available}
              field={item_type.always_available_form[:always_available]}
            />
          </.form>
        </:col>
        <:col :let={item_type} label="Available"><%= repr_bool(item_type.available) %></:col>
        <:col :let={item_type} label="Used in recipe">
          <%= repr_bool(item_type.used_in_recipe) %>
        </:col>
        <:action :let={item_type}>
          <%= if !item_type.available && !item_type.used_in_recipe do %>
            <.link
              class="hover:text-blue-800"
              phx-disable-with="Deleting..."
              phx-target={@myself}
              phx-click={
                JS.push("delete", value: %{id: item_type.id})
                |> JS.transition({"ease-in-out duration-300", "opacity-100", "opacity-50"},
                  time: 300,
                  to: "#item-#{item_type.id}"
                )
              }
            >
              Delete
            </.link>
          <% else %>
            <span class="text-gray-400 cursor-not-allowed">
              Delete
            </span>
          <% end %>
        </:action>
      </.table>
    </div>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Pantry.Stockpile.Household.Server.delete_item_type(socket.assigns.household_id, id)
    {:noreply, socket}
  end

  def handle_event("change-" <> item_type_id, %{"always_available" => always_available}, socket) do
    Pantry.Stockpile.Household.Server.update_item_type_always_available(
      socket.assigns.household_id,
      item_type_id,
      always_available
    )

    {:noreply, socket}
  end

  defp prepare_for_front(item_types, items, recipes) do
    item_types
    |> Enum.map(fn item_type ->
      available = Enum.any?(items, &(&1.item_type_id == item_type.id))

      used_in_recipe =
        Enum.any?(recipes, fn recipe ->
          Enum.any?(recipe.ingredients, &(&1.item_type_id == item_type.id))
        end)

      item_type
      |> Map.put(:available, available)
      |> Map.put(:used_in_recipe, used_in_recipe)
      |> Map.put(
        :always_available_form,
        to_form(ItemType.change_available(item_type, item_type.always_available))
      )
    end)
  end

  defp repr_bool(true), do: "Yes"
  defp repr_bool(false), do: "No"
end
