defmodule Pantry.Repo.Migrations.UnitAsEnum do
  use Ecto.Migration

  def up do
    # Create the enum type 
    execute "CREATE TYPE unit_enum AS ENUM ('kg', 'g', 'unit', 'l', 'ml', 'pack')"

    # Add a temporary column of the new type 
    alter table(:items) do
      add :unit_enum, :unit_enum
    end

    # Update the temporary column with values from the old column 
    execute """
    UPDATE items 
    SET unit_enum = unit::unit_enum 
    """

    # Drop the old column 
    alter table(:items) do
      remove :unit
    end

    # Rename the new column 
    rename table(:items), :unit_enum, to: :unit
  end

  def down do
    # Add a temporary string column 
    alter table(:items) do
      add :unit_string, :string
    end

    # Copy data from enum to string 
    execute """
    UPDATE items 
    SET unit_string = unit::text 
    """

    # Drop the enum column 
    alter table(:items) do
      remove :unit
    end

    # Rename the string column 
    rename table(:items), :unit_string, to: :unit

    # Drop the enum type 
    execute "DROP TYPE unit_enum"
  end
end
