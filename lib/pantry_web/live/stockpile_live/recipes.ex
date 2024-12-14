defmodule PantryWeb.StockpileLive.Recipes do
  use PantryWeb, :live_component

  alias Pantry.House.Recipe

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
     |> assign(recipes: filter_recipes(recipes, socket.assigns.search_form["search"].value))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={PantryWeb.Stockpile.AddRecipeForm}
        id="add-recipe-form"
        household_id={@household_id}
        title="Add Recipe"
        recipe={%Recipe{}}
      />
      <.inline_form
        for={@search_form}
        id="search-form"
        phx-change="search"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input field={@search_form[:search]} type="text" phx-debounce="200" placeholder="Search..." />
      </.inline_form>

      <.table id="recipes" rows={@recipes} row_id={&("recipe-" <> &1.id)}>
        <:col :let={recipe} label="Name"><%= recipe.name %></:col>
        <:col :let={recipe} label="Ingredients"><%= recipe.ingredients %></:col>
        <:col :let={recipe} label="Instructions"><%= recipe.instructions %></:col>
      </.table>
    </div>
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
    Pantry.Stockpile.Household.Server.delete_recipe(socket.assigns.household_id, id)
    {:noreply, socket}
  end

  defp search(socket, value) do
    filtered = filter_recipes(socket.assigns.original_recipes, value)

    assign(socket,
      recipes: filtered
    )
  end
end
