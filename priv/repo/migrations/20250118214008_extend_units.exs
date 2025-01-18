defmodule Pantry.Repo.Migrations.ExtendUnits do
  use Ecto.Migration

  def change do
    execute "ALTER TYPE unit_enum ADD VALUE IF NOT EXISTS 'cup'"
    execute "ALTER TYPE unit_enum ADD VALUE IF NOT EXISTS 'spoon'"
    execute "ALTER TYPE unit_enum ADD VALUE IF NOT EXISTS 'teaspoon'"
  end
end
