defmodule PantryWeb.Stockpile.AddRecipeForm do
  use PantryWeb, :live_component
  alias Pantry.House.Recipe
  alias Pantry.House.RecipeIngredient

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(form: nil)
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
        phx-change="change"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          placeholder="Scrambled eggs..."
          type="text"
          label="Name"
          id="first-input"
          phx-debounce="200"
        /> Ingredients
        <.inputs_for :let={ingredient_form} field={@form[:ingredients]}>
          <.input type="text" field={ingredient_form[:name]} placeholder="name" />
          <.input type="text" field={ingredient_form[:quantity]} placeholder="quantity" />
          <.input type="text" field={ingredient_form[:unit]} placeholder="unit" />
          <button
            type="button"
            name="recipe[ingredient_drop][]"
            value={ingredient_form.index}
            phx-click={JS.dispatch("change")}
          >
            <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
          </button>
        </.inputs_for>

        <button
          type="button"
          name="recipe[ingredients][]"
          value="new"
          phx-click={JS.dispatch("change")}
        >
          add more
        </button>

        <div id="submitedIngredients">
          <%= for ingredient <- @ingredients do %>
            <div>
              <span><%= ingredient.name <> ": " <> ingredient.quantity %></span>
              <.button
                type="button"
                phx-click={"remove_ingredient-" <> ingredient.id}
                phx-target={@myself}
              >
                x
              </.button>
            </div>
          <% end %>
        </div>
        <div id="ingredientsList">
          <div class="mt-10 m-2 flex flex-row">
            <.input
              name="search_ingredient"
              value={@search_ingredient}
              type="text"
              label="Search ingredient"
              placeholder="Egg"
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
            <.input
              name="quantity"
              value={@quantity}
              type="text"
              placeholder="3unit"
              label="Quantity"
              phx-change="update_quantity"
              phx-target={@myself}
              phx-debounce="200"
            />
            <.button type="button" phx-click="add_ingredient" phx-target={@myself}>+</.button>
          </div>
        </div>
        <.input
          field={@form[:instructions]}
          placeholder="Preheat the pan..."
          type="textarea"
          label="Instructions"
          phx-debounce="200"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    form =
      Recipe.changeset(assigns.recipe, %{})
      |> Ecto.Changeset.put_assoc(:ingredients, [%RecipeIngredient{}])
      |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: form)
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
  def handle_event("change", %{"recipe" => %{"ingredients" => ["new"]}}, socket) do
    current_form = socket.assigns.form
    current_ingredients = Ecto.Changeset.get_change(current_form.source, :ingredients, [])

    updated_changeset =
      current_form.source
      |> Ecto.Changeset.put_assoc(:ingredients, current_ingredients ++ [%RecipeIngredient{}])

    updated_form = to_form(updated_changeset)

    {:noreply, assign(socket, form: updated_form)}
  end

  def handle_event("change", %{"recipe" => recipe_params}, socket) do
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

    {:noreply,
     socket
     |> assign(search_ingredient: "")
     |> assign(quantity: "")}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    household_id = socket.assigns.household_id

    ingredients =
      Map.get(recipe_params, "ingredients")
      |> Enum.map(fn {_id, ingredient} ->
        item_type_id =
          Enum.find(socket.assigns.item_types, &(&1.name == Map.get(ingredient, "name"))).id

        Map.put(ingredient, "item_type_id", item_type_id)
      end)

    recipe_params =
      recipe_params
      |> Map.put("household_id", household_id)
      |> Map.put("ingredients", ingredients)

    dbg(recipe_params)

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
