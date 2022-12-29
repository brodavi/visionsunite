defmodule VisionsUnite.NewNotifications do
  @moduledoc """
  The NewNotifications context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.NewNotifications.NewNotification

  @doc """
  Returns the list of new_notifications.

  ## Examples

      iex> list_new_notifications()
      [%NewNotification{}, ...]

  """
  def list_new_notifications do
    Repo.all(NewNotification)
  end

  @doc """
  Returns the list of new_notifications for a particular user.

  ## Examples

      iex> list_new_notifications_for_user(user_id)
      [%NewNotification{}, ...]

  """
  def list_new_notifications_for_user(user_id) do
    query =
      from n in NewNotification,
        where: n.user_id == ^user_id

    Repo.all(query)
  end

  @doc """
  Returns the list of new_notifications for a particular expression.

  ## Examples

      iex> list_new_notifications_for_expression(expression_id)
      [%NewNotification{}, ...]

  """
  def list_new_notifications_for_expression(expression_id) do
    query =
      from ep in NewNotification,
        where: ep.expression_id == ^expression_id

    Repo.all(query)
  end

  @doc """
  Gets a single new_notification.

  Raises `Ecto.NoResultsError` if the NewNotification does not exist.

  ## Examples

      iex> get_new_notification!(123)
      %NewNotification{}

      iex> get_new_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_new_notification!(id), do: Repo.get!(NewNotification, id)

  @doc """
  Creates a new_notification.

  ## Examples

      iex> create_new_notification(%{field: value})
      {:ok, %NewNotification{}}

      iex> create_new_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_new_notification(attrs \\ %{}) do
    %NewNotification{}
    |> NewNotification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a new_notification.

  ## Examples

      iex> delete_new_notification(new_notification)
      {:ok, %NewNotification{}}

      iex> delete_new_notification(new_notification)
      {:error, %Ecto.Changeset{}}

  """
  def delete_new_notification(%NewNotification{} = new_notification) do
    Repo.delete(new_notification)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking new_notification changes.

  ## Examples

      iex> change_new_notification(new_notification)
      %Ecto.Changeset{data: %NewNotification{}}

  """
  def change_new_notification(%NewNotification{} = new_notification, attrs \\ %{}) do
    NewNotification.changeset(new_notification, attrs)
  end
end
