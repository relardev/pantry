defmodule PantryWeb.HouseholdAdminLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Pantry.House.Household,
      repo: Pantry.Repo,
      update_changeset: &Pantry.House.Household.update_changeset/3,
      create_changeset: &Pantry.House.Household.create_changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {PantryWeb.Layouts, :admin},
    pubsub: [
      name: Pantry.PubSub,
      topic: "households",
      event_prefix: "household_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Household"

  @impl Backpex.LiveResource
  def plural_name, do: "Households"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      }
    ]
  end
end

