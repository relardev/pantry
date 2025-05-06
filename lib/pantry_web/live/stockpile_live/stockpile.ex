defmodule PantryWeb.StockpileLive do
  use PantryWeb, :live_view

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

         {:ok,
          %{
            household: household
          }}
       end
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :overview, _params) do
    socket
    |> assign(:page_title, "Overview")
    |> assign(:nav, navigation(:overview))
  end

  defp apply_action(socket, :items, _params) do
    socket
    |> assign(:page_title, "Items")
    |> assign(:nav, navigation(:items))
  end

  defp apply_action(socket, :item_types, _params) do
    socket
    |> assign(:page_title, "Item Types")
    |> assign(:nav, navigation(:item_types))
  end

  defp apply_action(socket, :recipes, _params) do
    socket
    |> assign(:page_title, "Recipes")
    |> assign(:nav, navigation(:recipes))
  end

  defp apply_action(socket, :shopping_list, _params) do
    socket
    |> assign(:page_title, "Shopping List")
    |> assign(:nav, navigation(:shopping_list))
  end

  defp navigation(current) do
    [
      # %{url: "/app", label: "Overview", active: current == :overview},
      %{url: "/app/items", label: "Items", active: current == :items},
      %{url: "/app/item_types", label: "Item Types", active: current == :item_types},
      %{url: "/app/recipes", label: "Recipes", active: current == :recipes}
      # %{url: "/app/shopping-list", label: "Shopping List", active: current == :shopping_list}
    ]
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

      <PantryWeb.Stockpile.Navigation.nav items={@nav} />

      <div class="h-screen">
        <%= if @live_action == :items do %>
          <.live_component
            module={PantryWeb.StockpileLive.Items}
            id="items_list"
            household_id={household.id}
            items={household.items}
            item_types={household.item_types}
          />
        <% end %>
        <%= if @live_action == :item_types do %>
          <.live_component
            module={PantryWeb.StockpileLive.ItemTypes}
            id="item_types_list"
            household_id={household.id}
            items={household.items}
            item_types={household.item_types}
            recipes={household.recipes}
          />
        <% end %>
        <%= if @live_action == :recipes do %>
          <.live_component
            module={PantryWeb.StockpileLive.Recipes}
            id="recipes_list"
            household_id={household.id}
            recipes={household.recipes}
            item_types={household.item_types}
          />
        <% end %>
        <%= if @live_action == :shopping_list do %>
          <.live_component
            module={PantryWeb.StockpileLive.ShoppingLists}
            id="shopping_list"
            household_id={household.id}
            shopping_lists={household.shopping_lists}
            lists={household.shopping_lists}
            item_types={household.item_types}
          />
        <% end %>
      </div>
    </.async_result>
    """
  end

  @impl true
  def handle_info({:update, household}, state) do
    state =
      assign(state,
        household: AsyncResult.ok(household)
      )

    {:noreply, state}
  end

  defp remove_yourself(users, email) do
    users
    |> Enum.reject(fn user -> user.email == email end)
  end
end
