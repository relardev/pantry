defmodule PantryWeb.Stockpile.Navigation do
  # In Phoenix apps, the line is typically: use MyAppWeb, :html
  use PantryWeb, :html

  attr :items, :list

  def nav(assigns) do
    ~H"""
    <div class="flex">
      <%= for item <- @items do %>
        <div class="flex m-3">
          <span style="display: flex; align-items: center;">
            <.link
              patch={item.url}
              style={if item.active, do: "font-weight: bold; color: #2563eb;", else: ""}
            >
              <%= item.label %>
            </.link>
          </span>
        </div>
      <% end %>
    </div>
    """
  end
end
