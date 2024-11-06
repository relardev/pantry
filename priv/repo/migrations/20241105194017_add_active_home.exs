defmodule Pantry.Repo.Migrations.AddActiveHome do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :active_household_id, references(:households, on_delete: :nilify_all, type: :binary_id)
    end
  end
end
