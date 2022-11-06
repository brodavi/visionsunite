defmodule VisionsUnite.Expressions do
  @moduledoc """
  The Expressions context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Supports.Support
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionLinkages
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.SeekingSupports.SeekingSupport
  alias VisionsUnite.FullySupporteds.FullySupported
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.ExpressionSubscriptions.ExpressionSubscription

  @doc """
  Returns the preloaded expression or expressions

  ## Examples

      iex> preload(expressions)
      [%Expression{linked_expressions: [%Expression{}, %Expression{}]}, ...]

  """
  def preload_links(expr) do
    expr
    |> Repo.preload(:linked_expressions)
  end

  @doc """
  Returns the list of expressions.

  ## Examples

      iex> list_expressions()
      [%Expression{}, ...]

  """
  def list_expressions do
    Repo.all(Expression)
  end

  @doc """
  Returns the list of expressions that this user has ignored

  ## Examples

      iex> list_ignoreded_expressions(user_id)
      [%Expression{}, ...]

  """
  def list_ignored_expressions(user_id) do
    ignored_query =
      from e in Expression,
      join: es in ExpressionSubscription,
      on: es.expression_id == e.id and es.user_id == ^user_id,
      where: es.subscribe == false

    Repo.all(ignored_query)
  end

  @doc """
  Returns the list of expressions that have been fully supported.

  ## Examples

      iex> list_fully_supported_expressions(user_id)
      [%Expression{}, ...]

  """
  def list_fully_supported_expressions(user_id) do
    group_ids =
      ExpressionSubscriptions.list_expression_subscriptions_for_user(user_id)
      |> Enum.map(& &1.expression_id)

    fully_supported_by_group_query =
      from e in Expression,
      join: fs in FullySupported,
      on: fs.expression_id == e.id,
      join: es in ExpressionSubscription,
      where: es.expression_id == fs.group_id and
             fs.group_id in ^group_ids,
      distinct: true

    fully_supported_expressions_by_group =
      Repo.all(fully_supported_by_group_query)

    fully_supported_root_query =
      from e in Expression,
      join: fs in FullySupported,
      on: fs.expression_id == e.id,
      where: is_nil(fs.group_id)

    fully_supported_root_expressions =
      Repo.all(fully_supported_root_query)

    fully_supported_root_expressions ++ fully_supported_expressions_by_group
  end

  @doc """
  Returns the list of expressions authored by a particular user.

  ## Examples

      iex> list_expressions_authored_by_user(user_id)
      [%Expression{}, ...]

  """
  def list_expressions_authored_by_user(user_id) do
    # TODO this will, as advertised, return expressions authored by user
    # NOTE this will return even expressions that the author has ignored
    # SO! You should have another list in live.ex... "ignored expressions"
    # ... then you can let the liveview handle the de-duping
    query = from e in Expression,
      where: e.author_id == ^user_id

    Repo.all(query)
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
      where: es.user_id == ^user_id and
             es.subscribe == true

    Repo.all(query)
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
  end

  @doc """
  Gets a single expression's title.

  ## Examples

      iex> get_expression_title(123)
      "some expression title"
  """
  def get_expression_title(nil), do: nil
  def get_expression_title(id) do
    query =
      from e in Expression,
      where: e.id == ^id,
      select: [:title]
    result = Repo.one(query)
    result.title
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
    %Expression{}
    |> Expression.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a expression with linked expressions.

  ## Examples

      iex> create_expression(%{field: value}, [3,5,2...])
      {:ok, %Expression{}, seeking_supports}

      iex> create_expression(%{field: bad_value}, [3,5,2...])
      {:error, %Ecto.Changeset{}}

  """
  def create_expression(attrs, linked_expressions) do
    case create_expression(attrs) do
      {:ok, expression} ->

        # Try to link...
        linked_expressions
        |> Enum.each(fn linked_expression ->
          ExpressionLinkages.create_expression_linkage(%{
            expression_id: expression.id,
            link_id: linked_expression
          })
        end)

        # Let's now seek supporters for this expression
        seeking_supports =
          SeekingSupports.seek_supporters(expression)

        {:ok, expression, seeking_supports}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
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
end

