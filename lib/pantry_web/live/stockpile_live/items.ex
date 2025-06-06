defmodule PantryWeb.StockpileLive.Items do
  use PantryWeb, :live_component

  alias PantryWeb.StockpileLive.FormatNumber
  alias Pantry.House.Item

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(search_form: search_form(""))
     |> assign(compact: false)}
  end

  @impl true
  def update(%{items: items, item_types: item_types} = assigns, socket) do
    items =
      Enum.map(items, &add_name(&1, item_types))
      |> prepare_items_for_frontend()

    {:ok,
     socket
     |> assign(household_id: assigns.household_id)
     |> assign(original_items: items)
     |> assign(item_types: item_types)
     |> assign(
       items:
         items
         |> filter_items(socket.assigns.search_form["search"].value)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={PantryWeb.Stockpile.AddItemForm}
        id="add-item-form"
        household_id={@household_id}
        item_types={@item_types}
        title="Add Item"
        item={%Item{}}
        }
      />

      <div class="flex justify-between">
        <div class="flex items-center">
          <.form
            for={@search_form}
            id="search-form"
            phx-change="search"
            phx-submit="save"
            phx-target={@myself}
          >
            <.input
              field={@search_form[:search]}
              type="text"
              phx-debounce="200"
              placeholder="Search..."
            />
          </.form>
        </div>

        <div class="flex space-x-1">
          <div class="flex items-center">
            <.input
              type="checkbox"
              name="compact"
              id="compact"
              value={@compact}
              phx-click="toggle-compact"
              phx-target={@myself}
            />
          </div>
          <div class="flex items-center">Compact View</div>
        </div>
      </div>
      <%= if @compact do %>
        <.compact_table
          id="items"
          rows={Enum.with_index(@items)}
          row_id={&("item-" <> elem(&1, 0).id)}
        >
          <:col :let={{item, idx}} label="Name">
            <%= if idx > 0 && Enum.at(@items, idx - 1).item_type_id == item.item_type_id do %>
              <div class="text-gray-400">&nbsp&nbsp&nbsp&nbsp<%= item.name %></div>
            <% else %>
              <%= item.name %>
            <% end %>
          </:col>
          <:col :let={{item, _}} label="Quant">
            <%= item.quantity %>
          </:col>
          <:col :let={{item, _}} label="Unit">
            <%= item.unit %>
          </:col>
          <:col :let={{item, _}} label="Days Left"><%= days_left(item.expiration) %></:col>
        </.compact_table>
      <% else %>
        <.table id="items" rows={Enum.with_index(@items)} row_id={&("item-" <> elem(&1, 0).id)}>
          <:col :let={{item, idx}} label="Name">
            <%= if idx > 0 && Enum.at(@items, idx - 1).item_type_id == item.item_type_id do %>
              <div class="text-gray-400">&nbsp&nbsp&nbsp&nbsp<%= item.name %></div>
            <% else %>
              <%= item.name %>
            <% end %>
          </:col>
          <:col :let={{item, _}} label="Quant">
            <.small_form
              for={item.quantity_form}
              id={"quantity-form-" <> item.id}
              phx-change={"update_quantity-" <> item.id}
              phx-submit={"update_quantity-" <> item.id}
              phx-target={@myself}
            >
              <.input
                type="small_number"
                name="quantity"
                id={"item_quantity-" <> item.id}
                value={FormatNumber.format(item.quantity)}
                field={item.quantity_form[:quantity]}
                phx-debounce="200"
              />
            </.small_form>
          </:col>
          <:col :let={{item, _}} label="Unit">
            <.form
              for={item.unit_form}
              id={"unit-form-" <> item.id}
              phx-change={"update_unit-" <> item.id}
              phx-submit={"update_unit-" <> item.id}
              phx-target={@myself}
            >
              <.input
                type="select"
                name="unit"
                id={"item_unit-" <> item.id}
                value={item.unit}
                field={item.unit_form[:unit]}
                options={Pantry.House.Unit.buy_units()}
              />
            </.form>
          </:col>
          <:col :let={{item, _}} label="Expiration">
            <.form
              for={item.expiration_form}
              id={"expiration-form-" <> item.id}
              phx-change={"update_expiration-" <> item.id}
              phx-submit={"update_expiration-" <> item.id}
              phx-target={@myself}
            >
              <.input
                type="date"
                name="expiration"
                id={"item_expiration-" <> item.id}
                value={item.expiration}
                field={item.expiration_form[:expiration]}
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              />
            </.form>
          </:col>
          <:col :let={{item, _}} label="Days Left"><%= days_left(item.expiration) %></:col>
          <:action :let={{item, _}}>
            <.link
              phx-disable-with="Deleting..."
              phx-target={@myself}
              phx-click={
                JS.push("delete", value: %{id: item.id})
                |> JS.transition({"ease-in-out duration-300", "opacity-100", "opacity-50"},
                  time: 300,
                  to: "#item-#{item.id}"
                )
              }
            >
              Delete
            </.link>
          </:action>
        </.table>
      <% end %>
    </div>
    """
  end

  defp days_left(nil), do: nil

  defp days_left(expiration) do
    Date.diff(expiration, Date.utc_today())
  end

  defp search_form(value), do: to_form(%{"search" => value})

  defp filter_items(items, :default), do: items
  defp filter_items(items, ""), do: items

  defp filter_items(items, search) do
    items
    |> Enum.filter(fn item ->
      String.contains?(
        String.downcase(item.name),
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

  def handle_event("update_expiration-" <> item_id, %{"expiration" => value}, socket) do
    Pantry.Stockpile.Household.Server.update_item_expiration(
      socket.assigns.household_id,
      item_id,
      value
    )

    {:noreply, socket}
  end

  def handle_event("toggle-compact", %{}, socket) do
    {:noreply, assign(socket, compact: !socket.assigns.compact)}
  end

  defp search(socket, value) do
    filtered = filter_items(socket.assigns.original_items, value)

    assign(socket,
      items: filtered
    )
  end

  defp prepare_items_for_frontend(items) do
    mapped =
      Enum.reduce(items, %{}, fn item, acc ->
        Map.update(acc, item.item_type_id, [item], &List.flatten(&1, [item]))
      end)

    {items, _} =
      Enum.reduce(items, {[], mapped}, fn item, {all_items, mapped} ->
        {items, mapped} =
          case Map.get_and_update(mapped, item.item_type_id, fn _ -> :pop end) do
            {nil, mapped} -> {[], mapped}
            {items, mapped} -> {items, mapped}
          end

        {Enum.reverse(items) ++ all_items, mapped}
      end)

    items
    |> Enum.reverse()
    |> Enum.map(fn item ->
      item
      |> Map.put(:quantity_form, to_form(Item.update_quantity(item, item.quantity)))
      |> Map.put(:unit_form, to_form(Item.update_unit(item, item.unit)))
      |> Map.put(:expiration_form, to_form(Item.update_expiration(item, item.expiration)))
    end)
  end

  defp add_name(item, item_types) do
    item
    |> Map.put(
      :name,
      Enum.find(item_types, fn item_type -> item.item_type_id == item_type.id end).name
    )
  end
end
