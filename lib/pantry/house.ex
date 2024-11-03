defmodule Pantry.House do
  @moduledoc """
  The House context.
  """

  import Ecto.Query, warn: false
  alias Pantry.Repo

  alias Pantry.House.Household
  alias Pantry.House.HouseholdUser

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
end
