defmodule VisionsUnite.ExpressionParentages do
  @moduledoc """
  The ExpressionParentages context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.ExpressionParentages.ExpressionParentage

  @doc """
  Returns the list of expression_parentages.

  ## Examples

      iex> list_expression_parentages()
      [%ExpressionParentage{}, ...]

  """
  def list_expression_parentages do
    Repo.all(ExpressionParentage)
  end

  @doc """
  Returns the list of expression_parentages for a particular expression.

  ## Examples

      iex> list_expression_parentages_for_expression(expression_id)
      [%ExpressionParentage{}, ...]

  """
  def list_expression_parentages_for_expression(expression_id) do
    query = from ep in ExpressionParentage, where: ep.expression_id == ^expression_id
    Repo.all(query)
  end

  @doc """
  Returns the list of expression_parentages for a particular parent.

  ## Examples

      iex> list_expression_parentages_for_parent(parent_id)
      [%ExpressionParentage{}, ...]

  """
  def list_expression_parentages_for_parent(parent_id) do
    query = from ep in ExpressionParentage, where: ep.parent_id == ^parent_id
    Repo.all(query)
  end

  @doc """
  Gets a single expression_parentage.

  Raises `Ecto.NoResultsError` if the ExpressionParentage does not exist.

  ## Examples

      iex> get_expression_parentage!(123)
      %ExpressionParentage{}

      iex> get_expression_parentage!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expression_parentage!(id), do: Repo.get!(ExpressionParentage, id)

  @doc """
  Creates a expression_parentage.

  ## Examples

      iex> create_expression_parentage(%{field: value})
      {:ok, %ExpressionParentage{}}

      iex> create_expression_parentage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expression_parentage(attrs \\ %{}) do
    %ExpressionParentage{}
    |> ExpressionParentage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a expression_parentage.

  ## Examples

      iex> update_expression_parentage(expression_parentage, %{field: new_value})
      {:ok, %ExpressionParentage{}}

      iex> update_expression_parentage(expression_parentage, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expression_parentage(%ExpressionParentage{} = expression_parentage, attrs) do
    expression_parentage
    |> ExpressionParentage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a expression_parentage.

  ## Examples

      iex> delete_expression_parentage(expression_parentage)
      {:ok, %ExpressionParentage{}}

      iex> delete_expression_parentage(expression_parentage)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expression_parentage(%ExpressionParentage{} = expression_parentage) do
    Repo.delete(expression_parentage)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expression_parentage changes.

  ## Examples

      iex> change_expression_parentage(expression_parentage)
      %Ecto.Changeset{data: %ExpressionParentage{}}

  """
  def change_expression_parentage(%ExpressionParentage{} = expression_parentage, attrs \\ %{}) do
    ExpressionParentage.changeset(expression_parentage, attrs)
  end
end

