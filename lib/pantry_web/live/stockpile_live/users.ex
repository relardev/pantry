defmodule PantryWeb.Stockpile.Users do
  # In Phoenix apps, the line is typically: use MyAppWeb, :html
  use PantryWeb, :html

  attr :online_users, :list
  attr :offline_users, :list

  def lists(assigns) do
    ~H"""
    online users: <.users_list users={@online_users} />

    <br /> offline users: <.users_list users={@offline_users} />
    """
  end

  def users_list(assigns) do
    ~H"""
    <div class="flex">
      <%= for user <- @users do %>
        <div class="flex m-3">
          <%= if user.avatar_id do %>
            <img
              src={"/avatar/#{user.id}"}
              alt={"Avatar of #{user.email}"}
              class="user-avatar"
              width="64"
              height="64"
              style="object-fit: cover;"
            />
          <% end %>
          <span style="display: flex; align-items: center;">
            <%= if Map.get(user, :name) != nil  do %>
              <%= user.name %>
            <% else %>
              <%= user.email %>
            <% end %>
          </span>
        </div>
      <% end %>
    </div>
    """
  end
end
