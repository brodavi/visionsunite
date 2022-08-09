defmodule VisionsUnite.Expressions do
  @moduledoc """
  The Expressions context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Supports.Support
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.SeekingSupports.SeekingSupport
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.ExpressionSubscriptions.ExpressionSubscription

  @doc """
  Returns the list of expressions.

  ## Examples

      iex> list_expressions()
      [%Expression{}, ...]

  """
  def list_expressions do
    Repo.all(Expression)
    |> Repo.preload(:links)
  end

  @doc """
  Returns the list of expressions that have been fully supported.

  ## Examples

      iex> list_fully_supported_expressions()
      [%Expression{}, ...]

  """
  def list_fully_supported_expressions(user_id) do
    expression_subscriptions =
      ExpressionSubscriptions.list_expression_subscriptions_for_user(user_id)
      |> Enum.map(& &1.id)

    # Get all fully supported root expressions
    root_query = from e in Expression,
      where: e.author_id != ^user_id and not is_nil(e.fully_supported)

    root_expressions = Repo.all(root_query)

    # Get all fully supported subscribed expressions
    subscribed_query = from e in Expression,
      where: e.author_id != ^user_id and not is_nil(e.fully_supported),
      join: es in ExpressionSubscription,
      on: es.id in ^expression_subscriptions,
      where: es.user_id != ^user_id

    subscribed_expressions = Repo.all(subscribed_query)

    Enum.concat(root_expressions, subscribed_expressions)
    |> Enum.uniq()
    |> Repo.preload(:links)
  end

  @doc """
  Returns the list of expressions authored by a particular user.

  ## Examples

      iex> list_expressions_for_user(user_id)
      [%Expression{}, ...]

  """
  def list_expressions_for_user(user_id) do
    query = from i in Expression,
      where: i.author_id == ^user_id
    Repo.all(query)
    |> Repo.preload(:links)
  end

  @doc """
  Returns the list of expressions seeking support by a particular user.

  ## Examples

      iex> list_expressions_seeking_support_from_user(user_id)
      [%Expression{}, ...]

  """
  def list_expressions_seeking_support_from_user(user_id) do
    query = from i in Expression,
      join: se in SeekingSupport,
      on: i.id == se.expression_id,
      where: se.user_id == ^user_id

    Repo.all(query)
    |> Repo.preload(:links)
  end

  @doc """
  Returns the list of expressions subscribed by a particular user.

  ## Examples

      iex> list_subscribed_expressions_for_user(user_id)
      [%Expression{}, ...]

  """
  def list_subscribed_expressions_for_user(user_id) do
    query = from e in Expression,
      join: es in ExpressionSubscription,
      on: e.id == es.expression_id,
      where: es.user_id == ^user_id and e.author_id != ^user_id

    Repo.all(query)
    |> Repo.preload(:links)
  end

  @doc """
  Gets a single expression.

  Raises `Ecto.NoResultsError` if the Expression does not exist.

  ## Examples

      iex> get_expression!(123)
      %Expression{}

      iex> get_expression!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expression!(nil), do: nil
  def get_expression!(id) do
    Repo.get!(Expression, id)
    |> Repo.preload(:links)
  end

  @doc """
  Creates a expression.

  ## Examples

      iex> create_expression(%{field: value})
      {:ok, %Expression{}}

      iex> create_expression(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expression(attrs \\ %{}) do
    {:ok, expression} =
      %Expression{}
      |> Expression.changeset(attrs)
      |> Repo.insert()

    {:ok,
      expression
      |> Repo.preload([:links])}
  end

  @doc """
  Updates a expression.

  ## Examples

      iex> update_expression(expression, %{field: new_value})
      {:ok, %Expression{}}

      iex> update_expression(expression, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expression(%Expression{} = expression, attrs) do
    expression
    |> Expression.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks an expression as fully supported

  ## Examples

      iex> mark_fully_supported(expression)
      {:ok, %Expression{}}

  """
  def mark_fully_supported(%Expression{} = expression) do
    expression
    |> Expression.changeset(%{ fully_supported: DateTime.utc_now() })
    |> Repo.update()
  end

  @doc """
  Deletes a expression.

  ## Examples

      iex> delete_expression(expression)
      {:ok, %Expression{}}

      iex> delete_expression(expression)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expression(%Expression{} = expression) do
    Repo.delete(expression)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expression changes.

  ## Examples

      iex> change_expression(expression)
      %Ecto.Changeset{data: %Expression{}}

  """
  def change_expression(%Expression{} = expression, attrs \\ %{}) do
    Expression.changeset(expression, attrs)
  end

  def is_expression_fully_supported(expression, quorum) do
    query = from e in Support, where: e.expression_id == ^expression.id
    aggregate = Repo.aggregate(query, :sum, :support)
    case aggregate do
      nil ->
        false
      _ ->
        aggregate >= quorum
    end
  end
end

