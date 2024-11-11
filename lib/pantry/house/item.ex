defmodule Pantry.House.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "items" do
    field :name, :string
    field :quantity, :integer
    field :unit, :string
    field :expiration, :date

    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:name, :quantity, :expiration, :unit, :household_id])
    |> validate_required([:name, :household_id])
    |> unique_constraint([:name, :household_id],
      name: "items_name_household_id_index"
    )
  end
end
