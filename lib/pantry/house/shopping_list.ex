defmodule Pantry.House.ShoppingList do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shopping_lists" do
    field :name, :string

    has_many :items, Pantry.House.ShoppingListItem, on_replace: :delete_if_exists
    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shopping_list, attrs) do
    shopping_list
    |> cast(attrs, [:name, :household_id])
    |> validate_required([:household_id])
    |> cast_assoc(
      :items,
      with: &Pantry.House.ShoppingListItem.changeset/2
    )
  end

  def validate_changeset(shopping_list, attrs) do
    shopping_list
    |> cast(attrs, [:name])
    |> cast_assoc(
      :items,
      with: &Pantry.House.ShoppingListItem.validate_changeset/2
    )
  end
end
