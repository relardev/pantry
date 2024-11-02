defmodule Pantry.Repo.Migrations.DeleteHouseholdUserAssoc do
  use Ecto.Migration

  def up do
    drop constraint(:households_users, "households_users_household_id_fkey")

    alter table(:households_users) do
      modify :household_id, references(:households, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    drop constraint(:households_users, "households_users_household_id_fkey")

    alter table(:households_users) do
      modify :household_id, references(:households, on_delete: :nothing, type: :binary_id)
    end
  end
end
