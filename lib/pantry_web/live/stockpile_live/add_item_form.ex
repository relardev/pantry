defmodule PantryWeb.Stockpile.AddItemForm do
  use PantryWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.inline_form
        for={@form}
        id="add-item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:quantity]} type="text" label="Quantity" />
        <.input field={@form[:unit]} type="text" label="Unit" />
        <.input field={@form[:expiration]} type="date" label="Expiration" />
        <:actions>
          <.button phx-disable-with="Saving...">Add</.button>
        </:actions>
      </.inline_form>
    </div>
    """
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Pantry.House.Item.changeset(item, %{}))
     end)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset = Pantry.House.Item.changeset(socket.assigns.item, item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    household_id = socket.assigns.household_id
    item_params = Map.put(item_params, "household_id", household_id)

    case Pantry.Stockpile.Household.Server.add_item(household_id, item_params) do
      {:ok, item} ->
        notify_parent({:added, item})

        {:noreply,
         socket
         |> assign(item: %Pantry.House.Item{})
         |> assign(form: to_form(Pantry.House.Item.changeset(%Pantry.House.Item{}, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
