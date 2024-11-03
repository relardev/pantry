defmodule Pantry.HouseFixtures do
  alias Pantry.Repo

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pantry.House` context.
  """

  @doc """
  Generate a household.
  """
  def household_fixture(attrs \\ %{}) do
    user = Pantry.AccountsFixtures.user_fixture()

    household = household_for_user_fixture(user.id, attrs)

    {household, user}
  end

  def household_for_user_fixture(user_id, attrs \\ %{}) do
    {:ok, household} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Pantry.House.create_household_for_user(user_id)

    household
  end

  @doc """
  Generate a household_user.
  """
  def household_user_fixture(attrs \\ %{}) do
    {:ok, household_user} =
      attrs
      |> Enum.into(%{})
      |> Pantry.House.create_household_user()

    household_user
  end

  def binary_id, do: Ecto.UUID.generate()

  @doc """
  Generate a invite.
  """
  def invite_fixture() do
    invited = Pantry.AccountsFixtures.user_fixture()

    {invite, sender} = invite_for_user_fixture(invited.email)
    {invite, sender, invited}
  end

  def invite_for_user_fixture(email) do
    {household, sender} = household_fixture()

    {:ok, invite} =
      Pantry.House.create_invite(email, sender.id, household.id)

    {invite, sender}
  end

  def invite_preloaded_fixture() do
    {invite, sender, invited} = invite_fixture()

    invite =
      invite
      |> Repo.preload(:sender_user)
      |> Repo.preload(:invited_user)
      |> Repo.preload(:household)

    {invite, sender, invited}
  end
end
