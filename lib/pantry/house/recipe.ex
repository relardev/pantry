defmodule Pantry.House.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "recipes" do
    field :name, :string
    field :instructions, :string
    field :ingredients, :string

    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:name, :ingredients, :instructions, :household_id])
    |> validate_required([:name, :ingredients, :instructions, :household_id])
    |> unique_constraint([:name, :household_id],
      name: "recipes_name_household_id_index"
    )
  end
end
