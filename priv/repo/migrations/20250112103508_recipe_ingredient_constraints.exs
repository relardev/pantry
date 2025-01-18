defmodule Pantry.Repo.Migrations.RecipeIngredientConstraints do
  use Ecto.Migration

  def change do
    drop constraint(:recipe_ingredients, "recipe_ingredients_item_type_id_fkey")
    drop constraint(:recipe_ingredients, "recipe_ingredients_recipe_id_fkey")

    alter table(:recipe_ingredients) do
      modify :item_type_id, references(:item_types, type: :binary_id), null: false

      modify :recipe_id, references(:recipes, on_delete: :delete_all, type: :binary_id),
        null: false
    end
  end
end
