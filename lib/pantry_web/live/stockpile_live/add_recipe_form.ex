defmodule PantryWeb.Stockpile.AddRecipeForm do
  use PantryWeb, :live_component
  alias Pantry.House.Recipe

  @impl true
  def mount(socket) do
    form =
      Recipe.changeset(%Recipe{}, %{})
      |> to_form()

    {:ok,
     socket
     |> assign(form: form)
     |> assign(search_ingredient: "")
     |> assign(quantity: "")
     |> assign(ingredients: [])
     |> assign(household_id: "")
     |> assign(filtered_ingredients: [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      New Recipe
      <.simple_form
        for={@form}
        id="add-recipe-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" id="first-input" phx-debounce="200" />
        <div id="submitedIngredients">
          <%= for ingredient <- @ingredients do %>
            <div>
              <span><%= ingredient.name %></span>
              <.button
                type="button"
                phx-click={"remove_ingredient-" <> ingredient.id}
                phx-target={@myself}
              >
                Remove
              </.button>
            </div>
          <% end %>
        </div>
        <div id="ingredientsList">
          <div>
            <.input
              name="search_ingredient"
              value={@search_ingredient}
              type="text"
              label="Search ingredient"
              placeholder="Search ingredient"
              list="ingredientOptions"
              phx-change="suggest_ingredient"
              phx-target={@myself}
              phx-debounce="200"
            />
            <datalist id="ingredientOptions">
              <%= for ingredient <- @filtered_ingredients do %>
                <option value={ingredient}><%= ingredient %></option>
              <% end %>
            </datalist>
          </div>
          <.input
            name="quantity"
            value={@quantity}
            type="text"
            placeholder="Quantity"
            label="Quantity"
            phx-change="update_quantity"
            phx-target={@myself}
            phx-debounce="200"
          />
          <.button type="button" phx-click="add_ingredient" phx-target={@myself}>Add</.button>
        </div>
        <.input field={@form[:instructions]} type="textarea" label="Instructions" phx-debounce="200" />
        <:actions>
          <.button phx-disable-with="Saving...">Add</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(filtered_ingredients: filter(assigns.item_types, socket.assigns.search_ingredient))}
  end

  defp filter(item_types, search) do
    item_types
    |> Enum.filter(
      &String.contains?(
        String.downcase(&1.name),
        String.downcase(search)
      )
    )
    |> Enum.map(& &1.name)
    |> Enum.take(7)
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset = Recipe.changeset(socket.assigns.recipe, recipe_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event(
        "suggest_ingredient",
        %{
          "_target" => ["search_ingredient"],
          "search_ingredient" => ingredient
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(search_ingredient: ingredient)
     |> assign(filtered_ingredients: filter(socket.assigns.item_types, ingredient))}
  end

  def handle_event(
        "update_quantity",
        %{
          "_target" => ["quantity"],
          "quantity" => quantity
        },
        socket
      ) do
    {:noreply, assign(socket, quantity: quantity)}
  end

  def handle_event("add_ingredient", %{}, socket) do
    name = socket.assigns.search_ingredient

    item_type_id =
      Pantry.Stockpile.Household.Server.get_or_create_item_type(
        socket.assigns.household_id,
        socket.assigns.search_ingredient
      )

    socket =
      if Enum.find_index(socket.assigns.ingredients, &(&1.id == item_type_id)) do
        # Already added
        socket
      else
        ingredient =
          %{name: name, quantity: socket.assigns.quantity, id: item_type_id}

        socket
        |> assign(ingredients: socket.assigns.ingredients ++ [ingredient])
      end

    {:noreply, socket}
  end

  def handle_event(
        "remove_ingredient-" <> ingredient_id,
        _,
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       ingredients: Enum.filter(socket.assigns.ingredients, fn i -> i.id != ingredient_id end)
     )}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    household_id = socket.assigns.household_id

    recipe_params =
      recipe_params
      |> Map.put("household_id", household_id)
      |> Map.put("ingredients", JSON.encode!(socket.assigns.ingredients))

    with %Ecto.Changeset{errors: []} <- Recipe.changeset(%Recipe{}, recipe_params),
         {:ok, _} <- Pantry.Stockpile.Household.Server.add_recipe(household_id, recipe_params) do
      socket.assigns.on_success.()

      {:noreply,
       socket
       |> assign(recipe: %Recipe{})
       |> assign(form: to_form(Recipe.changeset(%Recipe{}, %{})))}
    else
      %Ecto.Changeset{} = changeset ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
