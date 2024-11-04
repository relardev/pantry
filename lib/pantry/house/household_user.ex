defmodule Pantry.House.HouseholdUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "households_users" do
    field :user_id, :binary_id
    field :household_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(household_user, attrs) do
    household_user
    |> cast(attrs, [:user_id, :household_id])
    |> validate_required([:user_id, :household_id])
    |> unique_constraint([:household_id, :user_id],
      name: "households_users_household_id_user_id_index"
    )
  end
end
