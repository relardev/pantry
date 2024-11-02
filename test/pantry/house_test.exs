defmodule Pantry.HouseTest do
  use Pantry.DataCase

  alias Pantry.House

  describe "households" do
    alias Pantry.House.Household

    import Pantry.HouseFixtures

    @invalid_attrs %{name: nil}

    test "list_households/0 returns all households" do
      household = household_fixture()
      assert House.list_households() == [household]
    end

    test "get_household!/1 returns the household with given id" do
      household = household_fixture()
      assert House.get_household!(household.id) == household
    end

    test "create_household/1 with valid data creates a household" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Household{} = household} = House.create_household(valid_attrs)
      assert household.name == "some name"
    end

    test "create_household/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = House.create_household(@invalid_attrs)
    end

    test "update_household/2 with valid data updates the household" do
      household = household_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Household{} = household} = House.update_household(household, update_attrs)
      assert household.name == "some updated name"
    end

    test "update_household/2 with invalid data returns error changeset" do
      household = household_fixture()
      assert {:error, %Ecto.Changeset{}} = House.update_household(household, @invalid_attrs)
      assert household == House.get_household!(household.id)
    end

    test "delete_household/1 deletes the household" do
      household = household_fixture()
      assert {:ok, %Household{}} = House.delete_household(household)
      assert_raise Ecto.NoResultsError, fn -> House.get_household!(household.id) end
    end

    test "change_household/1 returns a household changeset" do
      household = household_fixture()
      assert %Ecto.Changeset{} = House.change_household(household)
    end
  end

  describe "households_users" do
    alias Pantry.House.HouseholdUser

    import Pantry.HouseFixtures

    @invalid_attrs %{}

    test "list_households_users/0 returns all households_users" do
      household_user = household_user_fixture()
      assert House.list_households_users() == [household_user]
    end

    test "get_household_user!/1 returns the household_user with given id" do
      household_user = household_user_fixture()
      assert House.get_household_user!(household_user.id) == household_user
    end

    test "create_household_user/1 with valid data creates a household_user" do
      valid_attrs = %{}

      assert {:ok, %HouseholdUser{} = household_user} = House.create_household_user(valid_attrs)
    end

    test "create_household_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = House.create_household_user(@invalid_attrs)
    end

    test "update_household_user/2 with valid data updates the household_user" do
      household_user = household_user_fixture()
      update_attrs = %{}

      assert {:ok, %HouseholdUser{} = household_user} = House.update_household_user(household_user, update_attrs)
    end

    test "update_household_user/2 with invalid data returns error changeset" do
      household_user = household_user_fixture()
      assert {:error, %Ecto.Changeset{}} = House.update_household_user(household_user, @invalid_attrs)
      assert household_user == House.get_household_user!(household_user.id)
    end

    test "delete_household_user/1 deletes the household_user" do
      household_user = household_user_fixture()
      assert {:ok, %HouseholdUser{}} = House.delete_household_user(household_user)
      assert_raise Ecto.NoResultsError, fn -> House.get_household_user!(household_user.id) end
    end

    test "change_household_user/1 returns a household_user changeset" do
      household_user = household_user_fixture()
      assert %Ecto.Changeset{} = House.change_household_user(household_user)
    end
  end
end
