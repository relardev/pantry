defmodule PantryWeb.HouseholdLiveTest do
  use PantryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pantry.HouseFixtures
  import Pantry.AccountsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}
  @remember_me_cookie "_pantry_web_user_remember_me"

  defp create_household(%{conn: conn}) do
    household = household_for_user_fixture(conn.assigns.current_user.id, %{})
    %{household: household}
  end

  defp log_in(%{conn: conn}) do
    conn =
      conn
      |> Map.replace!(:secret_key_base, PantryWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = user_fixture()

    logged_in_conn =
      conn |> fetch_cookies() |> PantryWeb.UserAuth.log_in_user(user, %{"remember_me" => "true"})

    %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

    conn =
      conn
      |> put_req_cookie(@remember_me_cookie, signed_token)
      |> PantryWeb.UserAuth.fetch_current_user([])

    %{conn: conn}
  end

  describe "Index" do
    setup [:log_in, :create_household]

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
    setup [:log_in, :create_household]

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
