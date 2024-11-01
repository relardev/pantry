defmodule Pantry.Repo do
  use Ecto.Repo,
    otp_app: :pantry,
    adapter: Ecto.Adapters.Postgres
end
