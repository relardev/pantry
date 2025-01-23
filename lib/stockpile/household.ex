defmodule Pantry.Stockpile.Household do
  defstruct id: nil, name: nil, online_users: [], offline_users: []
end

defmodule Pantry.Stockpile.Household.Server do
  use GenServer

  def update_recipe(id, recipe_id, recipe_params) do
    GenServer.call(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_recipe, {recipe_id, recipe_params}},
      10_000
    )
  end

  def add_recipe(id, recipe) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), {:add_recipe, recipe}, 10_000)
  end

  def delete_recipe(id, recipe_id) do
    GenServer.call(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:delete_recipe, recipe_id},
      10_000
    )
  end

  def add_item(id, item) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), {:add_item, item}, 10_000)
  end

  def get_or_create_item_type(id, name) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), {:get_or_create_item_type, name})
  end

  def update_item_quantity(id, item_id, quantity) do
    GenServer.cast(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_item_quantity, item_id, quantity}
    )
  end

  def update_item_unit(id, item_id, unit) do
    GenServer.cast(Pantry.Stockpile.HouseholdRegistry.via(id), {:update_item_unit, item_id, unit})
  end

  def update_item_expiration(id, item_id, expiration) do
    GenServer.cast(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_item_expiration, item_id, expiration}
    )
  end

  def delete_item(id, item_id) do
    GenServer.call(Pantry.Stockpile.HouseholdRegistry.via(id), {:delete_item, item_id}, 10_000)
  end

  def delete_item_type(id, item_id) do
    GenServer.call(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:delete_item_type, item_id},
      10_000
    )
  end

  def update_item_type_always_available(id, item_type_id, always_available) do
    GenServer.cast(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_item_type_always_available, item_type_id, always_available}
    )
  end

  def update_item_type_name(id, item_type_id, name) do
    GenServer.cast(
      Pantry.Stockpile.HouseholdRegistry.via(id),
      {:update_item_type_name, item_type_id, name}
    )
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

  def handle_cast({:update_item_quantity, item_id, quantity}, household) do
    {:ok, item} = Pantry.House.update_item_quantity(item_id, quantity)

    items =
      Enum.map(household.items, fn i ->
        if i.id == item.id, do: %{i | quantity: item.quantity}, else: i
      end)

    household = Map.put(household, :items, items)
    broadcast_update(household)

    {:noreply, household}
  end

  def handle_cast({:update_item_unit, item_id, unit}, household) do
    {:ok, item} = Pantry.House.update_item_unit(item_id, unit)

    items =
      Enum.map(household.items, fn i ->
        if i.id == item.id, do: %{i | unit: item.unit}, else: i
      end)

    household = Map.put(household, :items, items)
    broadcast_update(household)

    {:noreply, household}
  end

  def handle_cast({:update_item_expiration, item_id, expiration}, household) do
    {:ok, item} = Pantry.House.update_item_expiration(item_id, expiration)

    items =
      Enum.map(household.items, fn i ->
        if i.id == item.id, do: %{i | expiration: item.expiration}, else: i
      end)
      |> sort_items()

    household = Map.put(household, :items, items)

    broadcast_update(household)

    {:noreply, household}
  end

  def handle_cast({:update_item_type_always_available, item_type_id, always_available}, household) do
    {:ok, _} =
      Pantry.House.update_item_type_always_available(item_type_id, always_available)

    item_types =
      Enum.map(household.item_types, fn it ->
        if it.id == item_type_id,
          do: Map.put(it, :always_available, always_available),
          else: it
      end)

    household = Map.put(household, :item_types, item_types)
    broadcast_update(household)

    {:noreply, household}
  end

  def handle_cast({:update_item_type_name, item_type_id, name}, household) do
    {:ok, _} = Pantry.House.update_item_type_name(item_type_id, name)

    item_types =
      Enum.map(household.item_types, fn it ->
        if it.id == item_type_id, do: Map.put(it, :name, name), else: it
      end)

    household = Map.put(household, :item_types, item_types)
    broadcast_update(household)

    {:noreply, household}
  end

  @impl true
  def handle_call(:get_household, _from, household) do
    {:reply, household, household}
  end

  def handle_call({:update_recipe, {recipe_id, recipe_params}}, _from, household) do
    recipe = Enum.find(household.recipes, fn r -> r.id == recipe_id end)
    {:ok, recipe} = Pantry.House.update_recipe(recipe, recipe_params)

    recipes =
      Enum.map(household.recipes, fn r ->
        if r.id == recipe.id, do: recipe, else: r
      end)

    household = Map.put(household, :recipes, recipes)
    broadcast_update(household)

    {:reply, {:ok, recipe}, household}
  end

  def handle_call({:add_recipe, recipe}, _from, household) do
    recipe = Map.put(recipe, "household_id", household.id)
    {:ok, recipe} = Pantry.House.create_recipe(recipe)

    household = Map.put(household, :recipes, [recipe | household.recipes])

    broadcast_update(household)
    {:reply, {:ok, recipe}, household}
  end

  def handle_call({:add_item, item}, _from, household) do
    {:ok, item} = Pantry.House.create_item(item)

    new_items =
      [item | household.items]
      |> sort_items()

    household = Map.put(household, :items, new_items)

    broadcast_update(household)
    {:reply, {:ok, item}, household}
  end

  def handle_call({:get_or_create_item_type, name}, _from, household) do
    item_type = Enum.find(household.item_types, fn it -> it.name == name end)

    if item_type do
      {:reply, item_type.id, household}
    else
      {:ok, item_type} = Pantry.House.create_item_type(%{name: name, household_id: household.id})
      item_types = [item_type | household.item_types]
      household = Map.put(household, :item_types, item_types)
      broadcast_update(household)

      {:reply, item_type.id, household}
    end
  end

  def handle_call({:delete_item, item_id}, _from, household) do
    {:ok, _} = Pantry.House.delete_item(item_id)
    items = Enum.reject(household.items, fn item -> item.id == item_id end)
    household = Map.put(household, :items, items)
    broadcast_update(household)

    {:reply, :ok, household}
  end

  def handle_call({:delete_item_type, item_type_id}, _from, household) do
    {:ok, _} = Pantry.House.delete_item_type(item_type_id)

    item_types =
      Enum.reject(household.item_types, fn item_type -> item_type.id == item_type_id end)

    household = Map.put(household, :item_types, item_types)
    broadcast_update(household)

    {:reply, :ok, household}
  end

  def handle_call({:delete_recipe, recipe_id}, _from, household) do
    {:ok, _} = Pantry.House.delete_recipe(recipe_id)
    recipes = Enum.reject(household.recipes, fn recipe -> recipe.id == recipe_id end)
    household = Map.put(household, :recipes, recipes)
    broadcast_update(household)

    {:reply, :ok, household}
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

  def sort_items(items) do
    items
    |> Enum.sort_by(
      & &1.expiration,
      fn
        nil, _ ->
          false

        _, nil ->
          true

        exp1, exp2 ->
          Date.compare(exp1, exp2) == :lt
      end
    )
  end
end
