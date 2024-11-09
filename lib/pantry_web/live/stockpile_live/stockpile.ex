defmodule PantryWeb.StockpileLive do
  use PantryWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{active_household_id: nil}}} = socket) do
    {:ok, push_navigate(socket, to: ~p"/households")}
  end

  def mount(_params, _session, socket) do
    household_id = socket.assigns.current_user.active_household_id

    socket =
      if connected?(socket) do
        Pantry.Stockpile.Household.ensure_started(household_id)

        household_id = socket.assigns.current_user.active_household_id

        Phoenix.PubSub.subscribe(
          Pantry.PubSub,
          "household:#{household_id}"
        )

        email = socket.assigns.current_user.email

        PantryWeb.Presence.track_user(household_id, email, %{id: email})
        PantryWeb.Presence.subscribe(household_id)

        online_users =
          PantryWeb.Presence.list_online_users(household_id)
          |> Enum.map(fn x ->
            %{metas: [%{id: email} | _]} = x
            email
          end)
          |> Enum.filter(&(&1 != email))

        assign(socket, online_users: online_users)
      else
        assign(socket, online_users: [])
      end

    {:ok,
     assign_async(
       socket,
       :household,
       fn ->
         {:ok, %{household: Pantry.Stockpile.Household.get_household(household_id)}}
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
      <PantryWeb.OnlineUsers.greet
        online_users={@online_users}
        offline_users={remove_online_users(household.users, @online_users, @current_user.email)}
      />
    </.async_result>
    """
  end

  @impl true
  def handle_info({:update, household}, state) do
    state = assign(state, household: AsyncResult.ok(household))
    {:noreply, state}
  end

  def handle_info(
        {PantryWeb.Presence, {:join, %{id: email}}},
        %{assigns: %{current_user: %{email: email}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info({PantryWeb.Presence, {:join, presence}}, socket) do
    {:noreply,
     assign(socket, online_users: [presence.id | socket.assigns.online_users] |> Enum.uniq())}
  end

  def handle_info(
        {PantryWeb.Presence, {:leave, %{id: email}}},
        %{assign: %{current_user: %{email: email}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info({PantryWeb.Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, assign(socket, online_users: socket.assigns.online_users -- [presence.id])}
    else
      {:noreply, socket}
    end
  end

  def remove_online_users(users, online_users, me) do
    Enum.reject(users, fn user -> Enum.member?(online_users, user.email) end)
    |> Enum.reject(fn user -> user.email == me end)
    |> Enum.map(fn user -> user.email end)
  end
end

defmodule PantryWeb.OnlineUsers do
  # In Phoenix apps, the line is typically: use MyAppWeb, :html
  use PantryWeb, :html

  attr :online_users, :list
  attr :offline_users, :list
  attr :you, :string

  def greet(assigns) do
    ~H"""
    online users:
    <%= for user <- @online_users do %>
      <%= user %>
    <% end %>
    <br /> offline users:
    <%= for user <- @offline_users do %>
      <%= user %>
    <% end %>
    """
  end
end
