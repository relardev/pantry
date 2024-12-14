defmodule Pantry.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :ingredients, :string
      add :instructions, :string
      add :household_id, references(:households, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:recipes, [:household_id])
  end
end
