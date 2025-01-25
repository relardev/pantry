defmodule Pantry.Repo.Migrations.AddPortionsToRecipe do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :portions, :float, default: 1
    end
  end
end
