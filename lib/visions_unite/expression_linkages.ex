defmodule VisionsUnite.ExpressionLinkages do
  @moduledoc """
  The ExpressionLinkages context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.ExpressionLinkages.ExpressionLinkage
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.FullySupporteds.FullySupported

  @doc """
  Returns the list of expression_linkages.

  ## Examples

      iex> list_expression_linkages()
      [%ExpressionLinkage{}, ...]

  """
  def list_expression_linkages do
    Repo.all(ExpressionLinkage)
  end

  @doc """
  Returns the list of expression_linkages for a particular expression.

  ## Examples

      iex> list_expression_linkages_for_expression(expression_id)
      [%ExpressionLinkage{}, ...]

  """
  def list_expression_linkages_for_expression(expression_id) do
    query =
      from ep in ExpressionLinkage,
        where: ep.expression_id == ^expression_id

    Repo.all(query)
  end

  @doc """
  Returns the list of parents for a particular expression and user.

  ## Examples

      iex> list_parents_for_expression_and_user(expression_id, user_id)
      [%Expression{}, ...]

  """
  def list_parents_for_expression_and_user(expression_id, nil) do
    query =
      from el in ExpressionLinkage,
        where: el.expression_id == ^expression_id

    Repo.all(query)
  end

  def list_parents_for_expression_and_user(expression_id, user_id) do
    group_ids =
      ExpressionSubscriptions.list_expression_subscriptions_for_user(user_id)
      |> Enum.map(& &1.expression_id)

    query =
      from el in ExpressionLinkage,
        where:
          el.expression_id == ^expression_id and
            el.link_id in ^group_ids

    Repo.all(query)
  end

  @doc """
  Returns the list of expression_linkages for a particular link.

  ## Examples

      iex> list_expression_linkages_for_link(link_id)
      [%ExpressionLinkage{}, ...]

  """
  def list_expression_linkages_for_link(link_id) do
    query =
      from ep in ExpressionLinkage,
        join: fs in FullySupported,
        on: fs.expression_id == ep.expression_id,
        where: ep.link_id == ^link_id

    Repo.all(query)
  end

  @doc """
  Gets a single expression_linkage.

  Raises `Ecto.NoResultsError` if the ExpressionLinkage does not exist.

  ## Examples

      iex> get_expression_linkage!(123)
      %ExpressionLinkage{}

      iex> get_expression_linkage!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expression_linkage!(id), do: Repo.get!(ExpressionLinkage, id)

  @doc """
  Creates a expression_linkage.

  ## Examples

      iex> create_expression_linkage(%{field: value})
      {:ok, %ExpressionLinkage{}}

      iex> create_expression_linkage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expression_linkage(attrs \\ %{}) do
    %ExpressionLinkage{}
    |> ExpressionLinkage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a expression_linkage.

  ## Examples

      iex> update_expression_linkage(expression_linkage, %{field: new_value})
      {:ok, %ExpressionLinkage{}}

      iex> update_expression_linkage(expression_linkage, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expression_linkage(%ExpressionLinkage{} = expression_linkage, attrs) do
    expression_linkage
    |> ExpressionLinkage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a expression_linkage.

  ## Examples

      iex> delete_expression_linkage(expression_linkage)
      {:ok, %ExpressionLinkage{}}

      iex> delete_expression_linkage(expression_linkage)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expression_linkage(%ExpressionLinkage{} = expression_linkage) do
    Repo.delete(expression_linkage)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expression_linkage changes.

  ## Examples

      iex> change_expression_linkage(expression_linkage)
      %Ecto.Changeset{data: %ExpressionLinkage{}}

  """
  def change_expression_linkage(%ExpressionLinkage{} = expression_linkage, attrs \\ %{}) do
    ExpressionLinkage.changeset(expression_linkage, attrs)
  end
end
