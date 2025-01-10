defmodule Pantry.House.Unit do
  @unit_enum ~w(kg g unit l ml pack)a

  def units() do
    @unit_enum
  end
end
