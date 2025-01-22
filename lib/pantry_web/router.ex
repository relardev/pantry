defmodule PantryWeb.Router do
  use PantryWeb, :router

  import PantryWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PantryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :admin do
    plug :require_authenticated_user, admin: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PantryWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pantry, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PantryWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PantryWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PantryWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PantryWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PantryWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", PantryWeb do
    pipe_through [:browser]

    get "/avatar/:user_id", AvatarController, :show

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PantryWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/", PantryWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", PageController, :home

    live_session :house,
      on_mount: [{PantryWeb.UserAuth, :ensure_authenticated}] do
      live "/app", StockpileLive, :overview
      live "/app/items", StockpileLive, :items
      live "/app/item_types", StockpileLive, :item_types
      live "/app/recipes", StockpileLive, :recipes
      live "/app/recipes/:action", StockpileLive, :recipes
      live "/app/shopping-list", StockpileLive, :shopping_list

      live "/households", HouseholdLive.Index, :index
      live "/households/new", HouseholdLive.Index, :new
      live "/households/:id/edit", HouseholdLive.Index, :edit
      live "/households/:id/invite", HouseholdLive.Index, :invite

      live "/households/:id", HouseholdLive.Show, :show
      live "/households/:id/show/edit", HouseholdLive.Show, :edit
      live "/households/:id/show/invite", HouseholdLive.Index, :invite

      live "/invites", InviteLive.Index, :index
      live "/invites/new", InviteLive.Index, :new
      live "/invites/:id/edit", InviteLive.Index, :edit

      live "/invites/:id", InviteLive.Show, :show
      live "/invites/:id/show/edit", InviteLive.Show, :edit
    end
  end

  import Backpex.Router

  scope "/admin", PantryWeb do
    pipe_through [:browser, :admin]

    backpex_routes()

    live_session :default, on_mount: Backpex.InitAssigns do
      live_resources "/households", HouseholdAdminLive
      live_resources "/users", UserAdminLive
      live_resources "/invites", InviteAdminLive
    end

    get "/", Redirect, to: "/admin/households"
  end
end
