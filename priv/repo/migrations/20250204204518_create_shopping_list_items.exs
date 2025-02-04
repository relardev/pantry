defmodule Pantry.Repo.Migrations.CreateShoppingListItems do
  use Ecto.Migration

  def change do
    rename table(:shopping_list), to: table(:shopping_lists)

    create table(:shopping_list_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :float
      add :unit, :unit_enum
      add :item_type_id, references(:item_types, on_delete: :delete_all, type: :binary_id)
      add :shopping_list_id, references(:shopping_lists, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_list_items, [:item_type_id])
    create index(:shopping_list_items, [:shopping_list_id])

    create unique_index(:shopping_list_items, [:item_type_id, :shopping_list_id])
  end
end
