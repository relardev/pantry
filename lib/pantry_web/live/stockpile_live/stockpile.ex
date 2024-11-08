defmodule PantryWeb.StockpileLive do
  use PantryWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{active_household_id: nil}}} = socket) do
    {:ok, push_navigate(socket, to: ~p"/households")}
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Pantry.Stockpile.Household.ensure_started(socket.assigns.current_user.active_household_id)

      Phoenix.PubSub.subscribe(
        Pantry.PubSub,
        "household:#{socket.assigns.current_user.active_household_id}"
      )
    end

    household_id = socket.assigns.current_user.active_household_id

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
      <br>
      <%= for user <- household.users do %>
        <%= user.email %> <br />
      <% end %>
    </.async_result>
    """
  end

  @impl true
  def handle_info({:update, household}, state) do
    state = assign(state, household: AsyncResult.ok(household))
    {:noreply, state}
  end
end
