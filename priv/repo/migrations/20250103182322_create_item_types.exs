defmodule Pantry.Repo.Migrations.CreateItemTypes do
  use Ecto.Migration
  import Ecto.Query

  def up do
    create table(:item_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :household_id, references(:households, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:item_types, [:household_id])
    create unique_index(:item_types, [:name, :household_id])

    alter table(:items) do
      add :item_type_id, references(:item_types, on_delete: :delete_all, type: :binary_id)
    end

    flush()

    distinct_items =
      Pantry.Repo.all(
        from(i in "items",
          select: {i.name, i.household_id},
          distinct: true
        )
      )

    Enum.each(distinct_items, fn {name, household_id} ->
      uuid = Ecto.UUID.generate() |> Ecto.UUID.dump() |> elem(1)

      Pantry.Repo.query!(
        "INSERT INTO item_types (id, name, household_id, inserted_at, updated_at) VALUES ($1, $2, $3, NOW(), NOW())",
        [uuid, name, household_id]
      )
    end)

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
