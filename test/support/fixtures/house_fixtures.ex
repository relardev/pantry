defmodule Pantry.HouseFixtures do
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
end
