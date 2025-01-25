defmodule PantryWeb.StockpileLive.Recipes do
  use PantryWeb, :live_component

  alias Pantry.House.Recipe

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(search_form: search_form(""))
     |> assign(action: :list)
     |> assign(selected_recipe: %Recipe{})}
  end

  @impl true
  def update(%{recipes: recipes} = assigns, socket) do
    recipes = prepare_recipe_ingredients_for_frontend(recipes, assigns.item_types)

    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
     |> assign(item_types: assigns.item_types)
     |> assign(original_recipes: recipes)
     |> assign(recipes: filter_recipes(recipes, socket.assigns.search_form["search"].value))}
  end

  def update(%{modal: "close"}, socket) do
    {:ok, assign(socket, action: "list")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link phx-target={@myself} phx-click={JS.push("action_add")}>(+) Add Recipe</.link>
      <.modal
        :if={@action in [:new, :edit]}
        id="add-recipe-modal"
        show
        on_cancel={JS.push("action_list", target: @myself)}
      >
        <.live_component
          module={PantryWeb.Stockpile.RecipeForm}
          id="add-recipe-form"
          household_id={@household_id}
          title="Add Recipe"
          action={@action}
          recipe={@selected_recipe}
          }
          item_types={@item_types}
          on_success={fn -> send_update(@myself, modal: "close") end}
        />
      </.modal>
      <.inline_form
        for={@search_form}
        id="search-form"
        phx-change="search"
        phx-submit="search_submit"
        phx-target={@myself}
      >
        <.input field={@search_form[:search]} type="text" phx-debounce="200" placeholder="Search..." />
      </.inline_form>

      <.table
        id="recipes"
        rows={@recipes}
        row_id={&("recipe-" <> &1.id)}
        row_click={fn recipe -> JS.push("action_edit", value: %{id: recipe.id}, target: @myself) end}
      >
        <:col :let={recipe} label="Name"><%= recipe.name %></:col>
        <:col :let={recipe} label="Ingredients">
          <%= for ing <- format_ingredients(recipe.ingredients) do %>
            <%= ing %> <br />
          <% end %>
        </:col>
        <:col :let={recipe} label="Portions"><%= recipe.portions %></:col>
        <:action :let={recipe}>
          <.link
            phx-disable-with="Deleting..."
            phx-target={@myself}
            phx-click={
              JS.push("delete", value: %{id: recipe.id})
              |> JS.transition({"ease-in-out duration-300", "opacity-100", "opacity-50"},
                time: 300,
                to: "#recipe-#{recipe.id}"
              )
            }
          >
            Delete
          </.link>
        </:action>
      </.table>
    </div>
    """
  end

  defp format_ingredients(ingredients) do
    ingredients
    |> Enum.map(fn %{name: name, quantity: quantity, unit: unit} ->
      unit =
        case unit do
          :unit -> ""
          u -> u
        end

      "#{name} - #{quantity}#{unit}"
    end)
  end

  defp search_form(value), do: to_form(%{"search" => value})

  defp filter_recipes(recipes, :default), do: recipes
  defp filter_recipes(recipes, ""), do: recipes

  defp filter_recipes(recipes, search) do
    recipes
    |> Enum.filter(fn recipe ->
      Enum.any?([
        String.contains?(
          String.downcase(recipe.name),
          String.downcase(search)
        ),
        String.contains?(
          String.downcase(recipe.instructions),
          String.downcase(search)
        ),
        Enum.any?(recipe.ingredients, fn ingredient ->
          String.contains?(
            String.downcase(ingredient.name),
            String.downcase(search)
          )
        end)
      ])
    end)
  end

  @impl true
  def handle_event("action_edit", %{"id" => recipe_id}, socket) do
    {:noreply,
     socket
     |> assign(action: :edit)
     |> assign(selected_recipe: Enum.find(socket.assigns.original_recipes, &(&1.id == recipe_id)))}
  end

  def handle_event("search", %{"_target" => ["search"], "search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  def handle_event("search_submit", %{"search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Pantry.Stockpile.Household.Server.delete_recipe(socket.assigns.household_id, id)
    {:noreply, socket}
  end

  def handle_event("action_add", _, socket) do
    {:noreply,
     socket
     |> assign(action: :new)
     |> assign(selected_recipe: %Recipe{})}
  end

  def handle_event("action_list", _, socket) do
    {:noreply, assign(socket, action: :list)}
  end

  defp search(socket, value) do
    filtered = filter_recipes(socket.assigns.original_recipes, value)

    assign(socket,
      recipes: filtered
    )
  end

  defp prepare_recipe_ingredients_for_frontend(recipes, item_types) do
    Enum.map(recipes, fn recipe ->
      ingredients =
        Enum.map(recipe.ingredients, fn ingredient ->
          name = Enum.find(item_types, &(&1.id == ingredient.item_type_id)).name

          Map.put(ingredient, :name, name)
        end)

      Map.put(recipe, :ingredients, ingredients)
    end)
  end
end
