defmodule Pantry.Repo.Migrations.CreateRecipeIngredients do
  use Ecto.Migration

  def change do
    create table(:recipe_ingredients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :float
      add :unit, :unit_enum
      add :item_type_id, references(:item_types, on_delete: :nothing, type: :binary_id)
      add :recipe_id, references(:recipes, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:recipe_ingredients, [:item_type_id])
    create index(:recipe_ingredients, [:recipe_id])
    create unique_index(:recipe_ingredients, [:item_type_id, :recipe_id])

    alter table(:recipes) do
      remove :ingredients
    end
  end
end
