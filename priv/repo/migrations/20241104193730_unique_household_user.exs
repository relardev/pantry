defmodule Pantry.Repo.Migrations.UniqueHouseholdUser do
  use Ecto.Migration

  def change do
    create unique_index(:households_users, [:household_id, :user_id])
  end
end
