defmodule Pantry.Repo.Migrations.UniqueInvitedAndHouseholdIndex do
  use Ecto.Migration

  def change do
    create unique_index(:invites, [:invited_user_id, :household_id])
  end
end
