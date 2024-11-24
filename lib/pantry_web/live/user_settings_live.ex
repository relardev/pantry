defmodule PantryWeb.UserSettingsLive do
  use PantryWeb, :live_view

  alias Pantry.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form for={@name_form} id="name_form" phx-submit="update_name">
          <.input field={@name_form[:name]} type="text" label="Name" required />
          <:actions>
            <.button phx-disable-with="Changing...">Change Name</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <form id="upload-form" phx-submit="save_avatar" phx-change="validate_file">
          <.live_file_input upload={@uploads.avatar} />
          <button type="submit">Upload</button>
        </form>
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <section phx-drop-target={@uploads.avatar.ref}>
          <%!-- render each avatar entry --%>
          <%= for entry <- @uploads.avatar.entries do %>
            <article class="upload-entry">
              <figure>
                <.live_img_preview entry={entry} />
                <figcaption><%= entry.client_name %></figcaption>
              </figure>

              <%!-- entry.progress will update automatically for in-flight entries --%>
              <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

              <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
              >
                &times;
              </button>

              <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
              <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                <p class="alert alert-danger"><%= error_to_string(err) %></p>
              <% end %>
            </article>
          <% end %>

          <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
          <%= for err <- upload_errors(@uploads.avatar) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </section>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok,
     socket
     |> push_navigate(to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    name_changeset = Accounts.change_user_name(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:name_form, to_form(name_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .gif .webp .svg .ico),
        max_entries: 1,
        max_file_size: 4_000_000
      )

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_name", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, user_params) do
      {:ok, _user} ->
        # redirect to reload layout so the new name is vsible
        {:noreply,
         socket
         |> redirect(to: ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  def handle_event("validate_file", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save_avatar", _params, socket) do
    user =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        {:ok, path} = convert_to_png(path)
        {:ok, user} = Pantry.Accounts.store_avatar(path, socket.assigns.current_user.email)
        {:ok, ~p"/avatar/#{user.id}"}
      end)

    {:noreply,
     socket
     |> assign(:current_user, user)
     |> put_flash(:info, "Avatar changed successfully.")
     |> push_navigate(to: ~p"/users/settings")}
  end

  def convert_to_png(path) do
    output_path = Path.rootname(path) <> ".png"

    case System.cmd("convert", [path, "-resize", "128x128^>", output_path]) do
      {_, 0} -> {:ok, output_path}
      {error, _} -> {:error, "Conversion failed: #{error}"}
    end
  end
end
