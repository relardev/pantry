defmodule Pantry.House.Unit do
  @unit_enum ~w(kg g unit l ml pack cup teaspoon spoon)a
  @unit_options [
    {"kg", "kg"},
    {"g", "g"},
    {"unit", "unit"},
    {"l", "l"},
    {"ml", "ml"},
    {"pack", "pack"},
    {"cup", "cup"},
    {"teaspoon", "teaspoon"},
    {"spoon", "spoon"}
  ]

  def units() do
    @unit_enum
  end

  def options() do
    @unit_options
  end

  def convert_unit_attr_to_atom(%{"unit" => unit} = attrs) when is_binary(unit) do
    Map.update!(attrs, "unit", &String.to_existing_atom/1)
  end

  def convert_unit_attr_to_atom(attrs), do: attrs
end
