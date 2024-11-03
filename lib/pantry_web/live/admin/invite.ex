defmodule PantryWeb.InviteAdminLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Pantry.House.Invite,
      repo: Pantry.Repo,
      update_changeset: &Pantry.House.Invite.update_changeset/3,
      create_changeset: &Pantry.House.Invite.create_changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    layout: {PantryWeb.Layouts, :admin},
    pubsub: [
      name: Pantry.PubSub,
      topic: "invites",
      event_prefix: "invite_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Invite"

  @impl Backpex.LiveResource
  def plural_name, do: "Invites"

  @impl Backpex.LiveResource
  def fields do
    [
      sender_user: %{
        module: Backpex.Fields.BelongsTo,
        label: "Sender",
        display_field: :email,
        live_resource: PantryWeb.UserAdminLive
      },
      invited_user: %{
        module: Backpex.Fields.BelongsTo,
        label: "Invited",
        display_field: :email,
        live_resource: PantryWeb.UserAdminLive
      },
      household: %{
        module: Backpex.Fields.BelongsTo,
        label: "Household",
        display_field: :name,
        live_resource: PantryWeb.HouseholdAdminLive
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
