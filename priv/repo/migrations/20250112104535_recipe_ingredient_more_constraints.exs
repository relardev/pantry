defmodule Pantry.Repo.Migrations.RecipeIngredientMoreConstraints do
  use Ecto.Migration

  def change do
    alter table(:recipe_ingredients) do
      modify :quantity, :float, null: false
      modify :unit, :unit_enum, null: false
    end
  end
end
