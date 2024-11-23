defmodule PantryWeb.StockpileLive.FormatNumber do
  def format(number) when is_float(number) do
    if number == trunc(number) do
      trunc(number)
    else
      number
    end
  end

  def format(number), do: number
end
