defmodule PantryWeb.HouseholdLiveTest do
  use PantryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pantry.HouseFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_household(_) do
    household = household_fixture()
    %{household: household}
  end

  describe "Index" do
    setup [:create_household]

    test "lists all households", %{conn: conn, household: household} do
      {:ok, _index_live, html} = live(conn, ~p"/households")

      assert html =~ "Listing Households"
      assert html =~ household.name
    end

    test "saves new household", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/households")

      assert index_live |> element("a", "New Household") |> render_click() =~
               "New Household"

      assert_patch(index_live, ~p"/households/new")

      assert index_live
             |> form("#household-form", household: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#household-form", household: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/households")

      html = render(index_live)
      assert html =~ "Household created successfully"
      assert html =~ "some name"
    end

    test "updates household in listing", %{conn: conn, household: household} do
      {:ok, index_live, _html} = live(conn, ~p"/households")

      assert index_live |> element("#households-#{household.id} a", "Edit") |> render_click() =~
               "Edit Household"

      assert_patch(index_live, ~p"/households/#{household}/edit")

      assert index_live
             |> form("#household-form", household: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#household-form", household: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/households")

      html = render(index_live)
      assert html =~ "Household updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes household in listing", %{conn: conn, household: household} do
      {:ok, index_live, _html} = live(conn, ~p"/households")

      assert index_live |> element("#households-#{household.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#households-#{household.id}")
    end
  end

  describe "Show" do
    setup [:create_household]

    test "displays household", %{conn: conn, household: household} do
      {:ok, _show_live, html} = live(conn, ~p"/households/#{household}")

      assert html =~ "Show Household"
      assert html =~ household.name
    end

    test "updates household within modal", %{conn: conn, household: household} do
      {:ok, show_live, _html} = live(conn, ~p"/households/#{household}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Household"

      assert_patch(show_live, ~p"/households/#{household}/show/edit")

      assert show_live
             |> form("#household-form", household: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#household-form", household: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/households/#{household}")

      html = render(show_live)
      assert html =~ "Household updated successfully"
      assert html =~ "some updated name"
    end
  end
end
