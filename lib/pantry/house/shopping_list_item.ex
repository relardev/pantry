defmodule Pantry.House.ShoppingListItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shopping_list_items" do
    field :unit, Ecto.Enum, values: Pantry.House.Unit.buy_units()
    field :quantity, :float
    belongs_to :item_type, Pantry.House.ItemType
    belongs_to :shopping_list, Pantry.House.ShoppingList

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shopping_list_item, attrs) do
    attrs = Pantry.House.Unit.convert_unit_attr_to_atom(attrs)

    shopping_list_item
    |> cast(attrs, [:quantity, :unit, :item_type_id, :shopping_list_id])
    |> validate_required([:quantity, :unit, :item_type_id])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
    |> validate_required([:item_type_id, :shopping_list_id],
      name: "shopping_list_items_item_type_id_shopping_list_id_index"
    )
  end

  def validate_changeset(shopping_list_item, attrs) do
    attrs = Pantry.House.Unit.convert_unit_attr_to_atom(attrs)

    shopping_list_item
    |> cast(attrs, [:unit, :item_type_id, :shopping_list_id])
    |> validate_required([:unit, :item_type_id])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
  end
end
