defmodule Pantry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PantryWeb.Telemetry,
      Pantry.Repo,
      {DNSCluster, query: Application.get_env(:pantry, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pantry.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Pantry.Finch},
      # Start a worker by calling: Pantry.Worker.start_link(arg)
      # {Pantry.Worker, arg},
      # Start to serve requests, typically the last entry

      Pantry.Stockpile.HouseholdRegistry,
      Pantry.Stockpile.Household.Server.supervisor_spec(),
      PantryWeb.Presence,
      PantryWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pantry.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PantryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
