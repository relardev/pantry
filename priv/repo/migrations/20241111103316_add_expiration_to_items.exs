defmodule Pantry.Repo.Migrations.AddExpirationToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :expiration, :date
    end
  end
end
