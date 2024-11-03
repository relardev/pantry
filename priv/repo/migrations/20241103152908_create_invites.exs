defmodule Pantry.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sender_user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :invited_user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :household_id, references(:households, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:invites, [:sender_user_id])
    create index(:invites, [:invited_user_id])
    create index(:invites, [:household_id])
  end
end
