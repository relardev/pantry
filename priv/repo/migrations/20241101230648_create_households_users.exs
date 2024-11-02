defmodule Pantry.Repo.Migrations.CreateHouseholdsUsers do
  use Ecto.Migration

  def change do
    create table(:households_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :household_id, references(:households, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:households_users, [:user_id])
    create index(:households_users, [:household_id])
  end
end
