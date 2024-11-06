defmodule PantryWeb.UserAdminLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Pantry.Accounts.User,
      repo: Pantry.Repo,
      update_changeset: &Pantry.Accounts.User.update_changeset/3,
      create_changeset: &Pantry.Accounts.User.create_changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {PantryWeb.Layouts, :admin},
    pubsub: [
      name: Pantry.PubSub,
      topic: "users",
      event_prefix: "user_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "User"

  @impl Backpex.LiveResource
  def plural_name, do: "Users"

  @impl Backpex.LiveResource
  def fields do
    [
      email: %{
        module: Backpex.Fields.Text,
        label: "Email"
      },
      admin: %{
        module: Backpex.Fields.Boolean,
        label: "Admin"
      },
      active_household: %{
        module: Backpex.Fields.BelongsTo,
        label: "Active Household",
        display_field: :name,
        live_resource: PantryWeb.HouseholdAdminLive,
        sort_by: :name
      },
      households: %{
        module: Backpex.Fields.HasMany,
        label: "Households",
        display_field: :name,
        live_resource: PantryWeb.HouseholdAdminLive,
        sort_by: :name
      },
      confirmed_at: %{
        module: Backpex.Fields.DateTime,
        label: "Confirmed At"
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Inserted At"
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At"
      }
    ]
  end
end
