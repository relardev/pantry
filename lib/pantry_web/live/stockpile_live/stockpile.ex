defmodule PantryWeb.StockpileLive do
  use PantryWeb, :live_view

  alias Pantry.House.Item
  alias Phoenix.LiveView.AsyncResult
  alias PantryWeb.StockpileLive.FormatNumber

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{active_household_id: nil}}} = socket) do
    {:ok, push_navigate(socket, to: ~p"/households")}
  end

  def mount(_params, _session, socket) do
    household_id = socket.assigns.current_user.active_household_id

    if connected?(socket) do
      Pantry.Stockpile.Household.Server.ensure_started(household_id)

      household_id = socket.assigns.current_user.active_household_id

      Phoenix.PubSub.subscribe(
        Pantry.PubSub,
        Pantry.Stockpile.Household.Server.topic(household_id)
      )

      user = socket.assigns.current_user
      email = user.email
      name = user.name

      PantryWeb.Presence.track_user(household_id, email, %{
        email: email,
        name: name,
        avatar_id: user.avatar_id,
        id: user.id
      })
    end

    {:ok,
     socket
     |> assign(household_id: household_id)
     |> assign(search_form: search_form(""))
     |> assign_async(
       :household,
       fn ->
         household =
           household_id
           |> Pantry.Stockpile.Household.Server.get_household()
           |> prepare_household_for_frontend()

         {:ok,
          %{
            household: household
          }}
       end
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={household} assign={@household}>
      <:loading>Loading Household...</:loading>
      <:failed :let={reason}><%= reason %></:failed>

      <span :if={household}><%= household.name %></span>
      <br />
      <PantryWeb.Stockpile.Users.lists
        online_users={remove_yourself(household.online_users, @current_user.email)}
        offline_users={remove_yourself(household.offline_users, @current_user.email)}
      />

      <br />

      <.live_component
        module={PantryWeb.Stockpile.AddItemForm}
        id="add-item-form"
        household_id={household.id}
        title="Add Item"
        item={%Item{}}
        }
      />

      <.inline_form for={@search_form} id="search-form" phx-change="search" phx-submit="save">
        <.input field={@search_form[:search]} type="text" phx-debounce="200" placeholder="Search..." />
      </.inline_form>

      <.table id="items" rows={household.items} row_id={&("item-" <> &1.id)}>
        <:col :let={item} label="Name"><%= item.name %></:col>
        <:col :let={item} label="Quant">
          <.small_form
            for={item.form}
            id={"quantity-form-" <> item.id}
            phx-change={"update_quantity-" <> item.id}
          >
            <.input
              type="small_number"
              name="quantity"
              id={"item_quantity-" <> item.id}
              value={FormatNumber.format(item.quantity)}
              field={item.form[:quantity]}
              phx-debounce="200"
            />
          </.small_form>
        </:col>
        <:col :let={item} label="Unit"><%= item.unit %></:col>
        <:col :let={item} label="Expiration"><%= item.expiration %></:col>
        <:col :let={item} label="Days Left"><%= days_left(item.expiration) %></:col>
        <:action :let={item}>
          <.link
            phx-disable-with="Deleting..."
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
    </.async_result>
    """
  end

  defp days_left(nil), do: nil

  defp days_left(expiration) do
    Date.diff(expiration, Date.utc_today())
  end

  @impl true
  def handle_info({:update, new_household}, state) do
    original_household = prepare_household_for_frontend(new_household)
    filtered = filter_items(original_household.items, state.assigns.search_form["search"].value)

    household = Map.put(original_household, :items, filtered)

    state =
      assign(state,
        household: AsyncResult.ok(household),
        original_household: original_household
      )

    {:noreply, state}
  end

  def handle_info({PantryWeb.Stockpile.AddItemForm, {:added, _item}}, state) do
    # TODO add item in the list
    {:noreply, state}
  end

  @impl true
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
      socket.assigns.household.result.items
      |> Enum.map(fn item ->
        if item.id == item_id do
          Map.put(item, :form, form)
        else
          item
        end
      end)

    {:noreply,
     assign(socket, household: AsyncResult.ok(%{socket.assigns.household.result | items: items}))}
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

  def handle_event("search", %{"_target" => ["search"], "search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  def handle_event("save", %{"search" => value}, socket) do
    socket = search(socket, value)
    {:noreply, socket}
  end

  defp remove_yourself(users, email) do
    users
    |> Enum.reject(fn user -> user.email == email end)
  end

  defp prepare_household_for_frontend(household) do
    items =
      household.items
      |> Enum.map(fn item ->
        Map.put(item, :form, to_form(Item.update_quantity(item, item.quantity)))
      end)

    Map.put(household, :items, items)
  end

  defp search(socket, value) do
    items = socket.assigns.original_household.items
    filtered = filter_items(items, value)

    assign(socket,
      household: AsyncResult.ok(Map.put(socket.assigns.original_household, :items, filtered)),
      search_form: search_form(value)
    )
  end

  defp search_form(value), do: to_form(%{"search" => value})

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
end
