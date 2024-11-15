defmodule Pantry.Repo.Migrations.AddAvatarId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_id, :integer
    end
  end
end
