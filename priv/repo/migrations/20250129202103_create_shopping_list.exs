defmodule Pantry.Repo.Migrations.CreateShoppingList do
  use Ecto.Migration

  def change do
    create table(:shopping_list, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :household_id, references(:households, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_list, [:household_id])
  end
end
