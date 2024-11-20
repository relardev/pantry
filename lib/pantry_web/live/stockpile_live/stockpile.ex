defmodule PantryWeb.StockpileLive do
  use PantryWeb, :live_view

  alias Pantry.House.Item
  alias Phoenix.LiveView.AsyncResult

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

      <.table id="items" rows={household.items}>
        <:col :let={item} label="Name"><%= item.name %></:col>
        <:col :let={item} label="Quantity">
          <.simple_form
            for={item.form}
            id={"quantity-form-" <> item.id}
            phx-change={"update_quantity-" <> item.id}
          >
            <.input
              type="number"
              name="quantity"
              value={format(item.quantity)}
              field={item.form[:quantity]}
              phx-debounce="200"
            />
          </.simple_form>
        </:col>
        <:col :let={item} label="Unit"><%= item.unit %></:col>
        <:col :let={item} label="Expiration"><%= item.expiration %></:col>
        <:col :let={item} label="Days Left"><%= days_left(item.expiration) %></:col>
        <:action :let={item}>
          <.link phx-click={JS.push("delete", value: %{id: item.id})}>
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

  def format(number) when is_float(number) do
    if number == trunc(number) do
      trunc(number)
    else
      number
    end
  end

  def format(number), do: number

  @impl true
  def handle_info({:update, household}, state) do
    household = prepare_household_for_frontend(household)
    state = assign(state, household: AsyncResult.ok(household))
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
end

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

defmodule PantryWeb.Stockpile.Users do
  # In Phoenix apps, the line is typically: use MyAppWeb, :html
  use PantryWeb, :html

  attr :online_users, :list
  attr :offline_users, :list

  def lists(assigns) do
    ~H"""
    online users: <.users_list users={@online_users} />

    <br /> offline users: <.users_list users={@offline_users} />
    """
  end

  def users_list(assigns) do
    ~H"""
    <div class="flex">
      <%= for user <- @users do %>
        <div class="flex m-3">
          <%= if user.avatar_id do %>
            <img
              src={"/avatar/#{user.id}"}
              alt={"Avatar of #{user.email}"}
              class="user-avatar"
              width="64"
              height="64"
              style="object-fit: cover;"
            />
          <% end %>
          <span style="display: flex; align-items: center;">
            <%= if Map.get(user, :name) != nil  do %>
              <%= user.name %>
            <% else %>
              <%= user.email %>
            <% end %>
          </span>
        </div>
      <% end %>
    </div>
    """
  end
end
