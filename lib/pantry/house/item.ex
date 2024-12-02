defmodule Pantry.House.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @unit_enum ~w(kg g unit l ml pack)a

  def units() do
    @unit_enum
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "items" do
    field :name, :string
    field :quantity, :float
    field :unit, Ecto.Enum, values: @unit_enum
    field :expiration, :date

    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    attrs = convert_unit_to_atom(attrs)

    item
    |> cast(attrs, [:name, :quantity, :expiration, :unit, :household_id])
    |> validate_required([:name, :household_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_inclusion(:unit, @unit_enum)
    |> unique_constraint([:name, :household_id],
      name: "items_name_household_id_index"
    )
  end

  defp convert_unit_to_atom(%{"unit" => unit} = attrs) when is_binary(unit) do
    Map.update!(attrs, "unit", &String.to_existing_atom/1)
  end

  defp convert_unit_to_atom(attrs), do: attrs

  def update_quantity(item, quantity) do
    item
    |> cast(%{quantity: quantity}, [:quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_required([:quantity])
  end

  def update_unit(item, unit) do
    item
    |> cast(%{unit: unit}, [:unit])
    |> validate_inclusion(:unit, @unit_enum)
    |> validate_required([:unit])
  end
end
