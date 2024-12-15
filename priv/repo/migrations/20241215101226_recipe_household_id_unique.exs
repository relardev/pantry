defmodule Pantry.Repo.Migrations.RecipeHouseholdIdUnique do
  use Ecto.Migration

  def change do
    create unique_index(:recipes, [:name, :household_id])
  end
end
