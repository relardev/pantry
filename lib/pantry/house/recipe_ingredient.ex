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
    attrs = Pantry.House.Unit.convert_unit_attr_to_atom(attrs)

    recipe_ingredient
    |> cast(attrs, [:quantity, :unit, :item_type_id, :recipe_id])
    |> validate_required([:quantity, :unit, :item_type_id])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
    |> unique_constraint([:item_type_id, :recipe_id],
      name: "recipe_ingredients_item_type_id_recipe_id_index"
    )
  end

  def validate_changeset(recipe_ingredient, attrs) do
    attrs = Pantry.House.Unit.convert_unit_attr_to_atom(attrs)

    recipe_ingredient
    |> cast(attrs, [:unit, :item_type_id, :recipe_id])
    |> validate_required([:unit, :item_type_id])
    |> validate_inclusion(:unit, Pantry.House.Unit.units())
  end
end
