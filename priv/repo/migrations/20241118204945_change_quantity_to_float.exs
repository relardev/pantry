defmodule Pantry.Repo.Migrations.ChangeQuantityToFloat do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :quantity, :float
    end
  end
end
