defmodule Pantry.Stockpile.Household do
  defstruct id: nil, name: nil, online_users: [], offline_users: []
end

defmodule Pantry.Stockpile.Household.Server do
  use GenServer

  def add_item(id, item) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), {:add_item, item})
  end

  def update_item_quantity(id, item_id, quantity) do
    GenServer.cast(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_item_quantity, item_id, quantity}
    )
  end

  def delete_item(id, item_id) do
    GenServer.cast(Pantry.Stockpile.HouseholdRegistry.via(id), {:delete_item, item_id})
  end

  def supervisor_spec() do
    {DynamicSupervisor, name: Pantry.Stockpile.HouseholdSupervisor, strategy: :one_for_one}
  end

  def get_household(id) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), :get_household)
  end

  def ensure_started(id) do
    DynamicSupervisor.start_child(
      Pantry.Stockpile.HouseholdSupervisor,
      {__MODULE__, id}
    )
  end

  def reload(id) do
    GenServer.cast(Pantry.Stockpile.HouseholdRegistry.via(id), :reload)
  end

  def started?(id) do
    case Registry.lookup(Pantry.Stockpile.HouseholdRegistry, id) do
      [] -> false
      [{_pid, _}] -> true
    end
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: Pantry.Stockpile.HouseholdRegistry.via(id))
  end

  @impl true
  def init(id) do
    {:ok, id, {:continue, :load}}
  end

  @impl true
  def handle_continue(:load, id) do
    PantryWeb.Presence.subscribe(id)

    {:noreply, load_data(id)}
  end

  @impl true
  def handle_cast(:reload, household) do
    {:noreply, load_data(household.id)}
  end

  def handle_cast({:delete_item, item_id}, household) do
    {:ok, _} = Pantry.House.delete_item(item_id)
    items = Enum.reject(household.items, fn item -> item.id == item_id end)
    household = Map.put(household, :items, items)
    broadcast_update(household)

    {:noreply, household}
  end

  def handle_cast({:update_item_quantity, item_id, quantity}, household) do
    {:ok, item} = Pantry.House.update_item_quantity(item_id, quantity)

    items =
      Enum.map(household.items, fn i ->
        if i.id == item_id, do: %{i | quantity: item.quantity}, else: i
      end)

    household = Map.put(household, :items, items)
    broadcast_update(household)

    {:noreply, household}
  end

  @impl true
  def handle_call(:get_household, _from, household) do
    {:reply, household, household}
  end

  def handle_call({:add_item, item}, _from, household) do
    {:ok, item} = Pantry.House.create_item(item)

    new_items =
      [item | household.items]
      |> Enum.sort_by(
        & &1.expiration,
        fn
          nil, _ -> false
          _, nil -> true
          exp1, exp2 -> exp1 < exp2
        end
      )

    household = Map.put(household, :items, new_items)

    broadcast_update(household)
    {:reply, {:ok, item}, household}
  end

  @impl true
  def handle_info({PantryWeb.Presence, {:join, %{metas: [meta | _]}}}, household) do
    online_users = [meta | household.online_users] |> Enum.uniq_by(& &1.email)

    offline_users =
      household.offline_users |> Enum.reject(fn user -> user.email == meta.email end)

    household =
      household
      |> Map.put(:online_users, online_users)
      |> Map.put(:offline_users, offline_users)

    Phoenix.PubSub.broadcast(Pantry.PubSub, topic(household.id), {:update, household})
    {:noreply, household}
  end

  def handle_info({PantryWeb.Presence, {:leave, presence}}, household) do
    if presence.metas == [] do
      online_users =
        household.online_users |> Enum.reject(fn user -> user.email == presence.id end)

      leaving_user =
        Enum.find(household.online_users, fn user -> user.email == presence.id end)

      leaving_user = %{
        email: presence.id,
        id: leaving_user.id,
        name: leaving_user.name,
        avatar_id: leaving_user.avatar_id
      }

      offline_users = [leaving_user | household.offline_users]

      household =
        household
        |> Map.put(:online_users, online_users)
        |> Map.put(:offline_users, offline_users)

      broadcast_update(household)
      {:noreply, household}
    else
      {:noreply, household}
    end
  end

  def topic(household_id) do
    "household:#{household_id}"
  end

  def load_data(id) do
    household = Pantry.House.get_household_with_users!(id)

    online_users =
      PantryWeb.Presence.list_online_users(id)
      |> Enum.map(fn x ->
        %{metas: [meta | _]} = x

        meta
      end)

    online_users_emails = Enum.map(online_users, & &1.email)

    offline_users =
      household.users
      |> Enum.reject(fn user -> user.email in online_users_emails end)

    household =
      household
      |> Map.put(:online_users, online_users)
      |> Map.put(:offline_users, offline_users)

    broadcast_update(household)

    household
  end

  def broadcast_update(household),
    do: Phoenix.PubSub.broadcast(Pantry.PubSub, topic(household.id), {:update, household})
end
