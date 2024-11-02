defmodule PantryWeb.HouseholdUserLiveTest do
  use PantryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pantry.HouseFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_household_user(_) do
    household_user = household_user_fixture()
    %{household_user: household_user}
  end

  describe "Index" do
    setup [:create_household_user]

    test "lists all households_users", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/households_users")

      assert html =~ "Listing Households users"
    end

    test "saves new household_user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/households_users")

      assert index_live |> element("a", "New Household user") |> render_click() =~
               "New Household user"

      assert_patch(index_live, ~p"/households_users/new")

      assert index_live
             |> form("#household_user-form", household_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#household_user-form", household_user: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/households_users")

      html = render(index_live)
      assert html =~ "Household user created successfully"
    end

    test "updates household_user in listing", %{conn: conn, household_user: household_user} do
      {:ok, index_live, _html} = live(conn, ~p"/households_users")

      assert index_live |> element("#households_users-#{household_user.id} a", "Edit") |> render_click() =~
               "Edit Household user"

      assert_patch(index_live, ~p"/households_users/#{household_user}/edit")

      assert index_live
             |> form("#household_user-form", household_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#household_user-form", household_user: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/households_users")

      html = render(index_live)
      assert html =~ "Household user updated successfully"
    end

    test "deletes household_user in listing", %{conn: conn, household_user: household_user} do
      {:ok, index_live, _html} = live(conn, ~p"/households_users")

      assert index_live |> element("#households_users-#{household_user.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#households_users-#{household_user.id}")
    end
  end

  describe "Show" do
    setup [:create_household_user]

    test "displays household_user", %{conn: conn, household_user: household_user} do
      {:ok, _show_live, html} = live(conn, ~p"/households_users/#{household_user}")

      assert html =~ "Show Household user"
    end

    test "updates household_user within modal", %{conn: conn, household_user: household_user} do
      {:ok, show_live, _html} = live(conn, ~p"/households_users/#{household_user}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Household user"

      assert_patch(show_live, ~p"/households_users/#{household_user}/show/edit")

      assert show_live
             |> form("#household_user-form", household_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#household_user-form", household_user: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/households_users/#{household_user}")

      html = render(show_live)
      assert html =~ "Household user updated successfully"
    end
  end
end
