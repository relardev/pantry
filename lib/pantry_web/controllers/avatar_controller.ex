defmodule PantryWeb.AvatarController do
  use PantryWeb, :controller

  alias Pantry.Accounts
  alias Pantry.Repo

  def show(conn, %{"user_id" => user_id}) do
    case Accounts.get_user_by_id(user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("User not found")

      user ->
        fetch_and_stream_avatar(conn, user.avatar_id)
    end
  end

  defp fetch_and_stream_avatar(conn, nil) do
    conn
    |> put_status(:not_found)
    |> text("Avatar not found")
  end

  defp fetch_and_stream_avatar(conn, avatar_id) do
    {:ok, conn} =
      Repo.transaction(fn ->
        {:ok, %{rows: [[fd]]}} = Repo.query("SELECT lo_open($1, $2)", [avatar_id, 0x00040000])

        stream =
          Stream.resource(
            fn -> 0 end,
            fn offset ->
              case Repo.query("SELECT loread($1, $2)", [fd, 8192]) do
                {:ok, %{rows: [[<<>>]]}} -> {:halt, offset}
                {:ok, %{rows: [[chunk]]}} -> {[chunk], offset + byte_size(chunk)}
              end
            end,
            fn _offset ->
              Repo.query("SELECT lo_close($1)", [fd])
            end
          )

        conn
        # Adjust content type as needed 
        |> put_resp_content_type("image/jpeg")
        |> send_chunked(200)
        |> stream_chunks(stream)
      end)

    conn
  end

  defp stream_chunks(conn, stream) do
    Enum.reduce_while(stream, conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, :closed} -> {:halt, conn}
      end
    end)
  end
end
