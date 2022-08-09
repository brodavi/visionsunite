defmodule VisionsUnite.ExpressionSubscriptions do
  @moduledoc """
  The ExpressionSubscriptions context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.ExpressionSubscriptions.ExpressionSubscription
  alias VisionsUnite.Expressions.Expression

  @doc """
  Returns the list of expression_subscriptions.

  ## Examples

      iex> list_expression_subscriptions()
      [%ExpressionSubscription{}, ...]

  """
  def list_expression_subscriptions do
    Repo.all(ExpressionSubscription)
  end

  @doc """
  Returns a count of expression_subscriptions for a particular expression.

  ## Examples

      iex> count_expression_subscriptions_for_expression(%Expression{})
      32

  """
  def count_expression_subscriptions_for_expression(expression) do
    query =
      from es in ExpressionSubscription,
      where: es.expression_id == ^expression.id

    Repo.aggregate(query, :count)
  end

  @doc """
  Returns the list of expression_subscriptions for a particular expression.

  ## Examples

      iex> list_expression_subscriptions_for_expression(expression)
      [%ExpressionSubscription{}, ...]

  """
  def list_expression_subscriptions_for_expression(expression_id) when is_number(expression_id) do
    query = from es in ExpressionSubscription,
      where: es.expression_id == ^expression_id

    Repo.all(query)
  end

  def list_expression_subscriptions_for_expression(expression) when is_map(expression) do
    query = from es in ExpressionSubscription,
      where: es.expression_id == ^expression.id

    Repo.all(query)
  end

  @doc """
  Returns the count of expression_subscriptions for a particular expression by its name.

  ## Examples

      iex> count_expression_subscriptions_for_expression_by_name(expression_name)
      [%ExpressionSubscription{}, ...]

  """
  def count_expression_subscriptions_for_expression_by_name(expression_title) do
    query = from es in ExpressionSubscription,
      join: e in Expression,
      on: e.id == es.expression_id,
      where: e.title == ^expression_title

    Repo.aggregate(query, :count)
  end

  @doc """
  Returns the list of expression_subscriptions for a particular user.

  ## Examples

      iex> list_expression_subscriptions_for_user(user_id)
      [%ExpressionSubscription{}, ...]

  """
  def list_expression_subscriptions_for_user(user_id) do
    query = from es in ExpressionSubscription, where: es.user_id == ^user_id
    Repo.all(query)
  end

  @doc """
  Gets a single expression_subscription.

  Raises `Ecto.NoResultsError` if the ExpressionSubscription does not exist.

  ## Examples

      iex> get_expression_subscription!(123)
      %ExpressionSubscription{}

      iex> get_expression_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expression_subscription!(id), do: Repo.get!(ExpressionSubscription, id)

  @doc """
  Gets a single expression_subscription by given expression_id and user_id.

  ## Examples

      iex> get_expression_subscription_for_expression_and_user!(245, 123)
      %ExpressionSubscription{}

  """
  def get_expression_subscription_for_expression_and_user(expression_id, user_id) do
    query =
      from es in ExpressionSubscription,
      where: es.expression_id == ^expression_id and es.user_id == ^user_id

    Repo.one(query)
  end

  @doc """
  Creates a expression_subscription.

  ## Examples

      iex> create_expression_subscription(%{field: value})
      {:ok, %ExpressionSubscription{}}

      iex> create_expression_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expression_subscription(attrs \\ %{}) do
    %ExpressionSubscription{}
    |> ExpressionSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a expression_subscription.

  ## Examples

      iex> update_expression_subscription(expression_subscription, %{field: new_value})
      {:ok, %ExpressionSubscription{}}

      iex> update_expression_subscription(expression_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expression_subscription(%ExpressionSubscription{} = expression_subscription, attrs) do
    expression_subscription
    |> ExpressionSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a expression_subscription.

  ## Examples

      iex> delete_expression_subscription(expression_subscription)
      {:ok, %ExpressionSubscription{}}

      iex> delete_expression_subscription(expression_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expression_subscription(%ExpressionSubscription{} = expression_subscription) do
    Repo.delete(expression_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expression_subscription changes.

  ## Examples

      iex> change_expression_subscription(expression_subscription)
      %Ecto.Changeset{data: %ExpressionSubscription{}}

  """
  def change_expression_subscription(%ExpressionSubscription{} = expression_subscription, attrs \\ %{}) do
    ExpressionSubscription.changeset(expression_subscription, attrs)
  end
end

