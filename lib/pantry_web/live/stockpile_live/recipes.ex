defmodule PantryWeb.StockpileLive.Recipes do
  use PantryWeb, :live_component

  alias PantryWeb.StockpileLive.FormatNumber
  alias Pantry.House.Item

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(search_form: search_form(""))}
  end

  @impl true
  def update(%{recipes: recipes} = assigns, socket) do
    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
     |> assign(original_recipes: recipes)
     |> assign(items: filter_recipes(recipes, socket.assigns.search_form["search"].value))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div></div>
    """
  end

  defp days_left(nil), do: nil

  defp days_left(expiration) do
    Date.diff(expiration, Date.utc_today())
  end

  defp search_form(value), do: to_form(%{"search" => value})

  defp filter_recipes(recipes, :default), do: recipes
  defp filter_recipes(recipes, ""), do: recipes

  defp filter_recipes(recipes, search) do
    recipes
    |> Enum.filter(fn recipe ->
      String.contains?(
        String.downcase(recipe.name),
        String.downcase(search)
      )
    end)
  end

  @impl true
  def handle_event("search", %{"_target" => ["search"], "search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  def handle_event("save", %{"search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Pantry.Stockpile.Household.Server.delete_item(socket.assigns.household_id, id)
    {:noreply, socket}
  end

  def handle_event("update_quantity-" <> item_id, %{"quantity" => ""}, socket) do
    form =
      %Item{}
      |> Item.update_quantity("")
      |> to_form(action: :validate)

    items =
      socket.assigns.items
      |> Enum.map(fn item ->
        if item.id == item_id do
          Map.put(item, :form, form)
        else
          item
        end
      end)

    {:noreply, assign(socket, items: items)}
  end

  def handle_event("update_quantity-" <> item_id, %{"quantity" => value}, socket) do
    case Float.parse(value) do
      {val, ""} ->
        Pantry.Stockpile.Household.Server.update_item_quantity(
          socket.assigns.household_id,
          item_id,
          val
        )

      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_event("update_unit-" <> item_id, %{"unit" => value}, socket) do
    Pantry.Stockpile.Household.Server.update_item_unit(
      socket.assigns.household_id,
      item_id,
      value
    )

    {:noreply, socket}
  end

  defp search(socket, value) do
    filtered = filter_recipes(socket.assigns.original_recipes, value)

    assign(socket,
      recipes: filtered
    )
  end
end
