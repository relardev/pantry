defmodule Pantry.Stockpile.Household do
  use GenServer

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

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: Pantry.Stockpile.HouseholdRegistry.via(id))
  end

  def init(id) do
    {:ok, id, {:continue, :load}}
  end

  def handle_continue(:load, id) do
    household = Pantry.House.get_household_with_users!(id)
    {:noreply, household}
  end

  def handle_call(:get_household, _from, household) do
    {:reply, household, household}
  end

  def handle_info(:load, household) do
    household = %{household | name: "Updated Household"}
    Phoenix.PubSub.broadcast(Pantry.PubSub, "household:#{household.id}", {:update, household})
    {:noreply, household}
  end
end
