defmodule PantryWeb.Stockpile.AddRecipeForm do
  use PantryWeb, :live_component
  alias Pantry.House.Recipe

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
        <.input field={@form[:ingredients]} type="textarea" label="Ingredients" phx-debounce="200" />
        <.input field={@form[:instructions]} type="textarea" label="Instructions" phx-debounce="200" />
        <:actions>
          <.button phx-disable-with="Saving...">Add</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{recipe: recipe} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Recipe.changeset(recipe, %{}))
     end)}
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset = Recipe.changeset(socket.assigns.recipe, recipe_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    household_id = socket.assigns.household_id

    recipe_params =
      recipe_params
      |> Map.put("household_id", household_id)

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
