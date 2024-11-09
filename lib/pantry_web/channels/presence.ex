defmodule PantryWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :pantry,
    pubsub_server: Pantry.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, _presence} <- joins do
      user_data = %{id: user_id, metas: Map.fetch!(presences, user_id)}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.broadcast(Pantry.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, _presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: user_id, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.broadcast(Pantry.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  def list_online_users(household_id) do
    list(topic(household_id)) |> Enum.map(fn {_id, presence} -> presence end)
  end

  def track_user(household_id, name, params), do: track(self(), topic(household_id), name, params)

  def subscribe(household_id),
    do: Phoenix.PubSub.subscribe(Pantry.PubSub, "proxy:#{topic(household_id)}")

  defp topic(household_id), do: "household_users:#{household_id}"
end
