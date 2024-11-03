defmodule Pantry.HouseTest do
  use Pantry.DataCase

  alias Pantry.House

  describe "households" do
    alias Pantry.House.Household

    import Pantry.HouseFixtures

    @invalid_attrs %{name: nil}

    test "list_households/0 returns all households" do
      {household, user} = household_fixture()
      assert House.list_households(user.id) == [household]
    end

    test "get_household!/1 returns the household with given id" do
      {household, user} = household_fixture()
      assert House.get_household!(household.id, user.id) == household
    end

    test "create_household/1 with valid data creates a household" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Household{} = household} = House.create_household(valid_attrs)
      assert household.name == "some name"
    end

    test "create household for user" do
      user = Pantry.AccountsFixtures.user_fixture()
      valid_attrs = %{name: "some name"}

      assert {:ok, %Household{} = household} =
               House.create_household_for_user(valid_attrs, user.id)

      assert household.name == "some name"
      assert House.get_household!(household.id, user.id) == household
    end

    test "create_household/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = House.create_household(@invalid_attrs)
    end

    test "update_household/2 with valid data updates the household" do
      {household, user} = household_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Household{} = household} =
               House.update_household_for_user(household, user.id, update_attrs)

      assert household.name == "some updated name"
    end

    test "update_household/2 with invalid data returns error changeset" do
      {household, user} = household_fixture()

      assert {:error, %Ecto.Changeset{}} =
               House.update_household_for_user(household, user.id, @invalid_attrs)

      assert household == House.get_household!(household.id, user.id)
    end

    test "delete_household/1 deletes the household" do
      {household, user} = household_fixture()
      assert {:ok, %Household{}} = House.delete_household(household)
      assert_raise Ecto.NoResultsError, fn -> House.get_household!(household.id, user.id) end
    end

    test "change_household/1 returns a household changeset" do
      {household, _user} = household_fixture()
      assert %Ecto.Changeset{} = House.change_household(household)
    end
  end
end
