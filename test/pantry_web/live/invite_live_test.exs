defmodule PantryWeb.InviteLiveTest do
  use PantryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pantry.HouseFixtures
  import Pantry.AccountsFixtures

  @remember_me_cookie "_pantry_web_user_remember_me"

  defp create_invite(%{conn: conn}) do
    {invite, sender} = invite_for_user_fixture(conn.assigns.current_user.email)
    %{invite: invite, sender: sender}
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
    setup [:log_in, :create_invite]

    test "lists all invites", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/invites")

      assert html =~ "Listing Invites"
    end

    test "deletes invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live |> element("#invites-#{invite.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#invites-#{invite.id}")
    end
  end
end
