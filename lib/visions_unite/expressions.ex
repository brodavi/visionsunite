defmodule VisionsUnite.Expressions do
  @moduledoc """
  The Expressions context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Supports.Support
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.SeekingSupports.SeekingSupport

  @doc """
  Returns the list of expressions.

  ## Examples

      iex> list_expressions()
      [%Expression{}, ...]

  """
  def list_expressions do
    Repo.all(Expression)
    |> Repo.preload(:parents)
  end

  @doc """
  Returns the list of expressions that have been fully supported.

  ## Examples

      iex> list_fully_supported_expressions()
      [%Expression{}, ...]

  """
  def list_fully_supported_expressions do
    expressions = Repo.all(Expression)
    quorum = SeekingSupports.get_quorum_num()
    expressions
    |> Enum.filter(fn expression ->
      is_expression_fully_supported(expression, quorum)
    end)
    |> Repo.preload(:parents)
  end

  @doc """
  Returns the list of expressions authored by a particular user.

  ## Examples

      iex> list_expressions_for_user(user_id)
      [%Expression{}, ...]

  """
  def list_expressions_for_user(user_id) do
    query = from i in Expression, where: i.author_id == ^user_id
    Repo.all(query)
    |> Repo.preload(:parents)
  end

  @doc """
  Returns the list of expressions seeking support by a particular user.

  ## Examples

      iex> list_expressions_seeking_support_from_user(user_id)
      [%Expression{}, ...]

  """
  def list_expressions_seeking_support_from_user(user_id) do
    query = from i in Expression, join: se in SeekingSupport, on: i.id == se.expression_id, where: se.user_id == ^user_id
    Repo.all(query)
    |> Repo.preload(:parents)
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
  def get_expression!(id) do
    Repo.get!(Expression, id)
    |> Repo.preload(:parents)
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
    expression =
      %Expression{}
      |> Expression.changeset(attrs)
      |> Repo.insert()
      |> VisionsUniteWeb.SharedPubSub.broadcast(:expression_created, "expressions")
    SeekingSupports.seek_supporters(expression)
    expression
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
    aggregate = Repo.aggregate(query, :avg, :support)
    case aggregate do
      nil ->
        false
      _ ->
        aggregate >= quorum
    end
  end
end

