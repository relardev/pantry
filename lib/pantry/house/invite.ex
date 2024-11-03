defmodule Pantry.House.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invites" do
    belongs_to :sender_user, Pantry.Accounts.User
    belongs_to :invited_user, Pantry.Accounts.User
    belongs_to :household, Pantry.House.Household

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:sender_user_id, :invited_user_id, :household_id])
    |> validate_required([:sender_user_id, :invited_user_id, :household_id])
  end

  def update_changeset(invite, attrs, _opts) do
    changeset(invite, attrs)
  end

  def create_changeset(invite, attrs, _opts) do
    changeset(invite, attrs)
  end
end
