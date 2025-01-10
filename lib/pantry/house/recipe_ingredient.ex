defmodule Pantry.House.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "recipe_ingredients" do
    field :unit, Ecto.Enum, values: Pantry.House.Unit.units()
    field :quantity, :float

    belongs_to :item_type, Pantry.House.ItemType
    belongs_to :recipe, Pantry.House.Recipe

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:quantity, :unit])
    |> validate_required([:quantity, :unit])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
    |> unique_constraint([:item_type_id, :recipe_id])
  end
end
