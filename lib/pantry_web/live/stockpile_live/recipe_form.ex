defmodule PantryWeb.Stockpile.RecipeForm do
  use PantryWeb, :live_component
  alias Pantry.House.Recipe
  alias Pantry.House.RecipeIngredient

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(form: nil)
     |> assign(ingredients: [])
     |> assign(household_id: "")
     |> assign(filtered_ingredients: [])}
  end

  @impl true
  def update(assigns, socket) do
    form =
      if assigns.recipe == %Recipe{} do
        Recipe.changeset(%Recipe{}, %{})
        |> Ecto.Changeset.put_assoc(:ingredients, [%RecipeIngredient{}])
        |> to_form()
      else
        Recipe.changeset(assigns.recipe, %{})
        |> to_form()
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: form)
     |> assign(title: title(assigns.action, assigns.recipe))}
  end

  defp title(:new, _), do: "Add Recipe"
  defp title(:edit, recipe), do: "Edit Recipe: " <> recipe.name

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= @title %>
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
        <datalist id="ingredientOptions">
          <%= for ingredient <- @filtered_ingredients do %>
            <option value={ingredient}><%= ingredient %></option>
          <% end %>
        </datalist>
        <.inputs_for :let={ingredient_form} field={@form[:ingredients]}>
          <div class="flex space-x-2 items-center">
            <.input
              type="text"
              field={ingredient_form[:name]}
              list="ingredientOptions"
              placeholder="name"
              autocapitalize="off"
            />
            <.input type="text" field={ingredient_form[:quantity]} placeholder="quantity" />
            <.input
              field={ingredient_form[:unit]}
              type="select"
              label="Unit"
              options={Pantry.House.Unit.options()}
            />
            <button
              type="button"
              name="recipe[ingredient_drop][]"
              value={ingredient_form.index}
              phx-click={JS.dispatch("change")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
            </button>
          </div>
        </.inputs_for>

        <br />
        <button
          type="button"
          name="recipe[ingredients][]"
          value="new"
          phx-click={JS.dispatch("change")}
        >
          add more ingredients
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
  def handle_event(
        "change",
        %{
          "_target" => ["recipe", "ingredients", idx, "name"],
          "recipe" => %{
            "ingredients" => ingredients
          }
        },
        socket
      ) do
    ingredient_name =
      ingredients
      |> Map.get(idx)
      |> Map.get("name")

    {:noreply,
     socket
     |> assign(
       filtered_ingredients:
         PantryWeb.Stockpile.ItemType.filter(socket.assigns.item_types, ingredient_name)
     )}
  end

  def handle_event(
        "change",
        %{
          "_target" => ["recipe", "ingredients", idx, "quantity"],
          "recipe" => %{
            "ingredients" => ingredients
          }
        },
        socket
      ) do
    ingredients = unpack_quantity_for(ingredients, idx)

    changeset = Recipe.validate_changeset(socket.assigns.recipe, %{"ingredients" => ingredients})

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("change", %{"recipe" => %{"ingredients" => ["new"]}}, socket) do
    current_form = socket.assigns.form
    current_ingredients = Ecto.Changeset.get_assoc(current_form.source, :ingredients)

    updated_changeset =
      current_form.source
      |> Ecto.Changeset.put_assoc(:ingredients, current_ingredients ++ [%RecipeIngredient{}])

    updated_form = to_form(updated_changeset)

    {:noreply, assign(socket, form: updated_form)}
  end

  def handle_event(
        "change",
        %{
          "_target" => ["recipe", "ingredient_drop"],
          "recipe" => %{"ingredient_drop" => [index]}
        },
        socket
      ) do
    current_form = socket.assigns.form
    current_changeset = current_form.source

    updated_changeset =
      current_changeset
      |> update_in([Access.key(:changes), :ingredients], fn ingredients ->
        case ingredients do
          nil ->
            current_ingredients = Ecto.Changeset.get_assoc(current_changeset, :ingredients)
            List.delete_at(current_ingredients, String.to_integer(index))

          list when is_list(list) ->
            List.delete_at(list, String.to_integer(index))
        end
      end)

    updated_form = to_form(updated_changeset)

    {:noreply, assign(socket, form: updated_form)}
  end

  def handle_event("change", %{"recipe" => recipe_params}, socket) do
    changeset = Recipe.validate_changeset(socket.assigns.recipe, recipe_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    household_id = socket.assigns.household_id

    ingredients =
      recipe_params
      |> Map.get("ingredients")
      |> Enum.map(fn {_id, ingredient} ->
        item_type_id =
          Pantry.Stockpile.Household.Server.get_or_create_item_type(
            socket.assigns.household_id,
            ingredient["name"]
          )

        ingredient
        |> Map.put("item_type_id", item_type_id)
      end)
      |> unpack_quantity_all()

    recipe_params =
      recipe_params
      |> Map.put("ingredients", ingredients)
      |> Map.put("household_id", household_id)

    save_recipe(socket.assigns.action, recipe_params, socket)
  end

  defp save_recipe(:edit, recipe_params, socket) do
    changeset = Recipe.changeset(socket.assigns.recipe, recipe_params)

    if changeset.valid? == true do
      {:ok, recipe} =
        Pantry.Stockpile.Household.Server.update_recipe(
          socket.assigns.household_id,
          socket.assigns.recipe.id,
          recipe_params
        )

      socket.assigns.on_success.()

      {:noreply,
       socket
       |> assign(recipe: recipe)
       |> assign(form: to_form(Recipe.changeset(%Recipe{}, %{})))}
    else
      {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_recipe(:new, recipe_params, socket) do
    with %Ecto.Changeset{errors: []} <- Recipe.changeset(%Recipe{}, recipe_params),
         {:ok, _} <-
           Pantry.Stockpile.Household.Server.add_recipe(
             socket.assigns.household_id,
             recipe_params
           ) do
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

  defp unpack_quantity_all(ingredients) do
    Enum.map(ingredients, fn ingredient ->
      {quantity, unit} = unpack_quantity(ingredient)

      ingredient
      |> Map.put("quantity", quantity)
      |> Map.put("unit", unit)
    end)
  end

  defp unpack_quantity_for(ingredients, idx) do
    ingredient = ingredients[idx]
    {quantity, unit} = unpack_quantity(ingredient)

    Map.put(
      ingredients,
      idx,
      ingredients[idx]
      |> Map.put("unit", unit)
      |> Map.put("quantity", quantity)
    )
  end

  defp unpack_quantity(ingredient) do
    quantity = Map.get(ingredient, "quantity")

    {quantity, unit} =
      case parse_quantity(quantity) do
        {:ok, quantity, unit} ->
          {quantity, unit}

        {:error, _} ->
          {ingredient["quantity"], ingredient["unit"]}
      end

    unit =
      if value_exists_in_second?(Pantry.House.Unit.options(), unit) do
        unit
      else
        ""
      end

    {quantity, unit}
  end

  defp value_exists_in_second?(list, value) do
    Enum.any?(list, fn {_, second_element} -> second_element == value end)
  end

  defp parse_quantity(input) do
    case Regex.run(~r/^([\d.]+)\s*([a-zA-Z]+)$/, input) do
      [_, quantity, unit] ->
        {:ok, String.trim(quantity), String.downcase(unit)}

      _ ->
        {:error, :invalid_format}
    end
  end
end
