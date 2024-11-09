defmodule Pantry.Repo.Migrations.AddItem do
  use Ecto.Migration

  def change do
    create table(:items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :quantity, :integer
      add :unit, :string

      add :household_id, references(:households, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:household_id])
    create unique_index(:items, [:name, :household_id])
  end
end
