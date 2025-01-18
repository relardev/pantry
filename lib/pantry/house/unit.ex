defmodule Pantry.House.Unit do
  @unit_enum ~w(kg g unit l ml pack)a
  @unit_options [
    {"kg", "kg"},
    {"g", "g"},
    {"unit", "unit"},
    {"l", "l"},
    {"ml", "ml"},
    {"pack", "pack"}
  ]

  def units() do
    @unit_enum
  end

  def options() do
    @unit_options
  end
end
