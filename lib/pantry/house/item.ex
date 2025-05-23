defmodule Pantry.House.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "items" do
    field :quantity, :float
    field :unit, Ecto.Enum, values: Pantry.House.Unit.units()
    field :expiration, :date

    belongs_to :household, Pantry.House.Household
    belongs_to :item_type, Pantry.House.ItemType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    attrs = Pantry.House.Unit.convert_unit_attr_to_atom(attrs)

    item
    |> cast(attrs, [:quantity, :expiration, :unit, :household_id, :item_type_id])
    |> validate_required([:item_type_id, :household_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
    |> unique_constraint([:name, :household_id],
      name: "items_name_household_id_index"
    )
  end

  def update_quantity(item, quantity) do
    item
    |> cast(%{quantity: quantity}, [:quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_required([:quantity])
  end

  def update_unit(item, unit) do
    item
    |> cast(%{unit: unit}, [:unit])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
    |> validate_required([:unit])
  end

  def update_expiration(item, expiration) do
    item
    |> cast(%{expiration: expiration}, [:expiration])
    |> validate_required([:expiration])
  end
end
