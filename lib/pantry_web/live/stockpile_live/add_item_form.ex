defmodule PantryWeb.Stockpile.AddItemForm do
  use PantryWeb, :live_component
  alias Pantry.House.Item

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(filtered_ingredients: [])}
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Item.changeset(item, %{}))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.inline_form
        for={@form}
        id="add-item-form"
        phx-target={@myself}
        phx-change="change"
        phx-submit="save"
      >
        <datalist id="ingredientOptions">
          <%= for ingredient <- @filtered_ingredients do %>
            <option value={ingredient}><%= ingredient %></option>
          <% end %>
        </datalist>
        <.input
          field={@form[:name]}
          type="text"
          list="ingredientOptions"
          label="Name"
          id="first-input"
          phx-debounce="200"
          autocapitalize="off"
        />
        <.input field={@form[:quantity]} type="text" label="Quantity" phx-debounce="200" />
        <.input
          field={@form[:unit]}
          type="select"
          label="Unit"
          options={Pantry.House.Unit.buy_units()}
        />
        <.input field={@form[:expiration]} type="date" label="Expiration" />
        <:actions>
          <.button phx-disable-with="Saving...">Add</.button>
        </:actions>
      </.inline_form>
    </div>
    """
  end

  @impl true
  def handle_event("change", %{"item" => item_params}, socket) do
    item_params = unpack_quantity(item_params)
    changeset = Item.changeset(socket.assigns.item, item_params)

    value = Map.get(item_params, "name", "")

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(
       filtered_ingredients: PantryWeb.Stockpile.ItemType.filter(socket.assigns.item_types, value)
     )}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    household_id = socket.assigns.household_id

    item_type_id =
      Pantry.Stockpile.Household.Server.get_or_create_item_type(household_id, item_params["name"])

    item_params =
      item_params
      |> unpack_quantity()
      |> Map.put("item_type_id", item_type_id)
      |> Map.put("household_id", household_id)

    with %Ecto.Changeset{errors: []} <- Item.changeset(%Item{}, item_params),
         {:ok, _} <- Pantry.Stockpile.Household.Server.add_item(household_id, item_params) do
      {:noreply,
       socket
       |> assign(item: %Item{})
       |> assign(form: to_form(Item.changeset(%Item{}, %{})))
       |> push_event("focus", %{id: "first-input"})}
    else
      %Ecto.Changeset{} = changeset ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp unpack_quantity(item_params) do
    [quantity_unit | days] =
      String.split(item_params["quantity"], " ", parts: 2)

    item_params = parse_days(item_params, days)

    {quantity, unit} =
      case parse_quantity(quantity_unit) do
        {:ok, quantity, unit} ->
          {quantity, unit}

        {:error, _} ->
          {item_params["quantity"], item_params["unit"]}
      end

    unit =
      if value_exists_in_second?(Pantry.House.Unit.options(), unit) do
        unit
      else
        ""
      end

    item_params
    |> Map.put("quantity", quantity)
    |> Map.put("unit", unit)
  end

  defp value_exists_in_second?(list, value) do
    Enum.any?(list, fn {_, second_element} -> second_element == value end)
  end

  defp parse_days(item_params, []), do: item_params

  defp parse_days(item_params, [days]) do
    case DateParser.parse_and_add_to_date(days) do
      {:ok, expiration} -> Map.put(item_params, "expiration", expiration)
      {:error, _} -> item_params
    end
  end

  def parse_quantity(input) do
    case Regex.run(~r/^([\d.]+)\s*([a-zA-Z]+)$/, input) do
      [_, quantity, unit] ->
        {:ok, String.trim(quantity), String.downcase(unit)}

      _ ->
        {:error, :invalid_format}
    end
  end
end

defmodule DateParser do
  def parse_and_add_to_date(input_string, start_date \\ Date.utc_today()) do
    case parse_time_string(input_string) do
      {:ok, value, unit} -> {:ok, add_time(start_date, value, unit)}
      {:error, err} -> {:error, err}
    end
  end

  defp parse_time_string(""), do: {:error, "Empty time string"}

  defp parse_time_string(time_string) do
    case Regex.run(~r/^(\d+)(d|w|m)?$/, time_string) do
      [_, value, "d"] -> {:ok, String.to_integer(value), :days}
      [_, value, "w"] -> {:ok, String.to_integer(value), :weeks}
      [_, value, "m"] -> {:ok, String.to_integer(value), :months}
      # Default to days if no unit specified 
      [_, value] -> {:ok, String.to_integer(value), :days}
      _ -> {:error, "Invalid time string format: #{time_string}"}
    end
  end

  defp add_time(date, value, :days), do: Date.shift(date, day: value)
  defp add_time(date, value, :weeks), do: Date.shift(date, week: value)
  defp add_time(date, value, :months), do: Date.shift(date, month: value)
end
