defmodule Pantry.House.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "recipes" do
    field :name, :string
    field :instructions, :string
    field :portions, :float, default: 1.0

    has_many :ingredients, Pantry.House.RecipeIngredient, on_replace: :delete_if_exists
    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:name, :instructions, :portions, :household_id])
    |> validate_required([:name, :household_id])
    |> validate_number(:portions, greater_than: 0)
    |> unique_constraint([:name, :household_id],
      name: "recipes_name_household_id_index"
    )
    |> cast_assoc(:ingredients, with: &Pantry.House.RecipeIngredient.changeset/2, required: true)
  end

  def validate_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:name, :portions, :instructions])
    |> validate_required([:name])
    |> validate_number(:portions, greater_than: 0)
    |> cast_assoc(:ingredients,
      with: &Pantry.House.RecipeIngredient.validate_changeset/2,
      required: true
    )
  end
end
