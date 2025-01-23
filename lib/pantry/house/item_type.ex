defmodule Pantry.House.ItemType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "item_types" do
    field :name, :string
    field :household_id, :binary_id
    field :always_available, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item_type, attrs) do
    item_type
    |> cast(attrs, [:name, :household_id])
    |> validate_required([:name, :household_id])
    |> unique_constraint([:name, :household_id], name: "item_types_name_household_id_index")
  end

  def change_available(item_type, always_available) do
    item_type
    |> cast(%{always_available: always_available}, [:always_available])
    |> validate_required([:always_available])
  end

  def change_name(item_type, name) do
    item_type
    |> cast(%{name: name}, [:name])
    |> validate_required([:name])
  end
end
