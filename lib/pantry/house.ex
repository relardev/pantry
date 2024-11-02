defmodule Pantry.House do
  @moduledoc """
  The House context.
  """

  import Ecto.Query, warn: false
  alias Pantry.Repo

  alias Pantry.House.Household

  @doc """
  Returns the list of households.

  ## Examples

      iex> list_households()
      [%Household{}, ...]

  """
  def list_households do
    Repo.all(Household)
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
  def get_household!(id), do: Repo.get!(Household, id)

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
  Returns the list of households_users.

  ## Examples

      iex> list_households_users()
      [%HouseholdUser{}, ...]

  """
  def list_households_users do
    Repo.all(HouseholdUser)
  end

  @doc """
  Gets a single household_user.

  Raises `Ecto.NoResultsError` if the Household user does not exist.

  ## Examples

      iex> get_household_user!(123)
      %HouseholdUser{}

      iex> get_household_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_household_user!(id), do: Repo.get!(HouseholdUser, id)

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

  @doc """
  Updates a household_user.

  ## Examples

      iex> update_household_user(household_user, %{field: new_value})
      {:ok, %HouseholdUser{}}

      iex> update_household_user(household_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_household_user(%HouseholdUser{} = household_user, attrs) do
    household_user
    |> HouseholdUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a household_user.

  ## Examples

      iex> delete_household_user(household_user)
      {:ok, %HouseholdUser{}}

      iex> delete_household_user(household_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_household_user(%HouseholdUser{} = household_user) do
    Repo.delete(household_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking household_user changes.

  ## Examples

      iex> change_household_user(household_user)
      %Ecto.Changeset{data: %HouseholdUser{}}

  """
  def change_household_user(%HouseholdUser{} = household_user, attrs \\ %{}) do
    HouseholdUser.changeset(household_user, attrs)
  end
end
