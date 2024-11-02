defmodule Pantry.HouseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pantry.House` context.
  """

  @doc """
  Generate a household.
  """
  def household_fixture(attrs \\ %{}) do
    {:ok, household} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Pantry.House.create_household()

    household
  end

  @doc """
  Generate a household_user.
  """
  def household_user_fixture(attrs \\ %{}) do
    {:ok, household_user} =
      attrs
      |> Enum.into(%{

      })
      |> Pantry.House.create_household_user()

    household_user
  end
end
