defmodule Pantry.Repo.Migrations.AddAlwaysAvailableItemType do
  use Ecto.Migration

  def change do
    alter table(:item_types) do
      add :always_available, :boolean, default: false
    end
  end
end
