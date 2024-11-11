defmodule Pantry.House do
  @moduledoc """
  The House context.
  """

  import Ecto.Query, warn: false
  alias Pantry.Repo

  alias Pantry.House.Household
  alias Pantry.House.HouseholdUser
  alias Pantry.House.Item

  @doc """
  Returns the list of households.

  ## Examples

      iex> list_households()
      [%Household{}, ...]

  """
  def list_households(user_id) do
    household_for_user(user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single household.

  Raises `Ecto.NoResultsError` if the Household does not exist.

  ## Examples

      iex> get_household!(123)
      %Household{}

      iex> get_household!(456)
      ** (Ecto.NoResultsError)

  """
  def get_household_with_users!(id) do
    Household
    |> preload([:users, :items])
    |> Repo.get!(id)
  end

  def get_household!(id, user_id) do
    household_for_user(user_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a household.

  ## Examples

      iex> create_household(%{field: value})
      {:ok, %Household{}}

      iex> create_household(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_household(attrs \\ %{}) do
    %Household{}
    |> Household.changeset(attrs)
    |> Repo.insert()
  end

  def create_household_for_user(attrs, user_id) do
    Repo.transaction(fn ->
      with {:ok, household} <- create_household(attrs),
           {:ok, _} <- create_household_user(%{household_id: household.id, user_id: user_id}) do
        household
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a household.

  ## Examples

      iex> update_household(household, %{field: new_value})
      {:ok, %Household{}}

      iex> update_household(household, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_household(%Household{} = household, attrs) do
    household
    |> Household.changeset(attrs)
    |> Repo.update()
  end

  def user_has_access_to_household?(household_id, user_id) do
    from(
      hu in HouseholdUser,
      where: hu.household_id == ^household_id,
      where: hu.user_id == ^user_id,
      select: count(hu.id)
    )
    |> Repo.one!() > 0
  end

  def update_household_for_user(%Household{} = household, user_id, attrs) do
    Repo.transaction(fn ->
      with true <- user_has_access_to_household?(household.id, user_id),
           {:ok, updated} <- update_household(household, attrs) do
        updated
      else
        {:error, changeset} -> Repo.rollback(changeset)
        false -> Repo.rollback(:no_access)
      end
    end)
  end

  @doc """
  Deletes a household.

  ## Examples

      iex> delete_household(household)
      {:ok, %Household{}}

      iex> delete_household(household)
      {:error, %Ecto.Changeset{}}

  """
  def delete_household(%Household{} = household) do
    Repo.delete(household)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking household changes.

  ## Examples

      iex> change_household(household)
      %Ecto.Changeset{data: %Household{}}

  """
  def change_household(%Household{} = household, attrs \\ %{}) do
    Household.changeset(household, attrs)
  end

  alias Pantry.House.HouseholdUser

  @doc """
  Creates a household_user.

  ## Examples

      iex> create_household_user(%{field: value})
      {:ok, %HouseholdUser{}}

      iex> create_household_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_household_user(attrs \\ %{}) do
    %HouseholdUser{}
    |> HouseholdUser.changeset(attrs)
    |> Repo.insert()
  end

  defp household_for_user(user_id) do
    Household
    |> join(:inner, [h], hu in assoc(h, :users))
    |> where([h, hu], hu.id == ^user_id)
  end

  def get_household_user(household_id, user_id) do
    from(
      hu in HouseholdUser,
      where: hu.household_id == ^household_id,
      where: hu.user_id == ^user_id
    )
    |> Repo.one()
  end

  def delete_household_user(%HouseholdUser{} = household_user) do
    Repo.delete(household_user)
  end

  alias Pantry.House.Invite

  @doc """
  Returns the list of invites.

  ## Examples

      iex> list_invites()
      [%Invite{}, ...]

  """
  def list_invites(user_id) do
    Invite
    |> where([i], i.invited_user_id == ^user_id)
    |> preload([:sender_user, :invited_user, :household])
    |> Repo.all()
  end

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invite{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invite!(id, user_id) do
    Invite
    |> where([i], i.invited_user_id == ^user_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invite(email, sender_user_id, household_id, opts \\ []) do
    Repo.transaction(fn ->
      with invited_user <- Pantry.Accounts.get_user_by_email(email),
           true <- invited_user != nil,
           true <- invited_user.id != sender_user_id,
           nil <- get_household_user(household_id, invited_user.id),
           {:ok, invite} <-
             %Invite{}
             |> Invite.changeset(%{
               sender_user_id: sender_user_id,
               invited_user_id: invited_user.id,
               household_id: household_id
             })
             |> Repo.insert() do
        preload = Keyword.get(opts, :preload, nil)

        if preload do
          Enum.reduce(preload, invite, fn field, acc ->
            Repo.preload(acc, field)
          end)
        else
          invite
        end
      else
        {:error, changeset} ->
          Repo.rollback(changeset)

        false ->
          Repo.rollback(:user_not_found)

        %HouseholdUser{} ->
          Repo.rollback(:already_member)
      end
    end)
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invite{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end

  def accept_invite!(id, user_id) do
    {:ok, household_user} =
      Repo.transaction(fn ->
        with invite <- get_invite!(id, user_id),
             {:ok, household_user} <-
               create_household_user(%{
                 household_id: invite.household_id,
                 user_id: user_id
               }),
             {:ok, _} <- delete_invite(invite) do
          household_user
        end
      end)

    household_user
  end

  def create_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end
end
