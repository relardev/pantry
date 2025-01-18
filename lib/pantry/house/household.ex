defmodule Pantry.House.Household do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "households" do
    field :name, :string
    has_many :items, Pantry.House.Item
    has_many :item_types, Pantry.House.ItemType
    has_many :recipes, Pantry.House.Recipe
    many_to_many :users, Pantry.Accounts.User, join_through: Pantry.House.HouseholdUser

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(household, attrs) do
    household
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def update_changeset(household, attrs, _opts) do
    changeset(household, attrs)
  end

  def create_changeset(household, attrs, _opts) do
    changeset(household, attrs)
  end
end
