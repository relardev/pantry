defmodule PantryWeb.StockpileLive.Recipes do
  use PantryWeb, :live_component

  alias Pantry.House.Recipe

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(search_form: search_form(""))
     |> assign(action: :list)}
  end

  @impl true
  def update(%{recipes: recipes} = assigns, socket) do
    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
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
        :if={@action == :add_recipe}
        id="add-recipe-modal"
        show
        on_cancel={JS.push("action_list", target: @myself)}
      >
        <.live_component
          module={PantryWeb.Stockpile.AddRecipeForm}
          id="add-recipe-form"
          household_id={@household_id}
          title="Add Recipe"
          recipe={%Recipe{}}
          on_success={fn -> send_update(@myself, modal: "close") end}
        />
      </.modal>
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

  def handle_event("action_add", _, socket) do
    {:noreply, assign(socket, action: :add_recipe)}
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
end
