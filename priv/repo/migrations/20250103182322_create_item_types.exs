defmodule Pantry.Repo.Migrations.CreateItemTypes do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""

    create table(:item_types, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()"), null: false
      add :name, :string, null: false
      add :household_id, references(:households, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:item_types, [:household_id])
    create unique_index(:item_types, [:name, :household_id])

    alter table(:items) do
      add :item_type_id, references(:item_types, on_delete: :delete_all, type: :binary_id)
    end

    execute(
      "INSERT INTO item_types (name, household_id, inserted_at, updated_at) SELECT DISTINCT name, household_id, NOW(), NOW() FROM items"
    )

    execute(
      "UPDATE items SET item_type_id = (SELECT id FROM item_types WHERE item_types.name = items.name and item_types.household_id = items.household_id)"
    )

    drop constraint(:items, "items_item_type_id_fkey")

    alter table(:items) do
      modify :item_type_id, references(:item_types, on_delete: :delete_all, type: :binary_id),
        null: false
    end

    create index(:items, [:item_type_id])

    alter table(:items) do
      remove :name
    end
  end

  def down do
    alter table(:items) do
      add :name, :string
    end

    execute(
      "UPDATE items SET name = (SELECT name FROM item_types WHERE item_types.id = items.item_type_id)"
    )

    alter table(:items) do
      remove :item_type_id
    end

    drop table(:item_types)
  end
end
