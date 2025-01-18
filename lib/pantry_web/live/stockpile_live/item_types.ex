defmodule PantryWeb.Stockpile.ItemType do
  def filter(item_types, search) do
    item_types
    |> Enum.filter(
      &String.contains?(
        String.downcase(&1.name),
        String.downcase(search)
      )
    )
    |> Enum.map(& &1.name)
    |> Enum.take(7)
  end
end
