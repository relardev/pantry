defmodule Pantry.House.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "recipes" do
    field :name, :string
    field :instructions, :string
    field :ingredients, :string
    field :household_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:name, :ingredients, :instructions])
    |> validate_required([:name, :ingredients, :instructions])
  end
end
