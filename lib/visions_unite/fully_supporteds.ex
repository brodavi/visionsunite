defmodule VisionsUnite.FullySupporteds do
  @moduledoc """
  The FullySupporteds context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Supports.Support
  alias VisionsUnite.FullySupporteds.FullySupported
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.SeekingSupports

  @doc """
  Returns the list of fully_supporteds.

  ## Examples

      iex> list_fully_supporteds()
      [%FullySupported{}, ...]

  """
  def list_fully_supporteds do
    Repo.all(FullySupported)
  end

  @doc """
  Returns the list of fully_supporteds for a particular expression.

  ## Examples

      iex> list_fully_supporteds_for_expression(expression_id)
      [%FullySupported{}, ...]

  """
  def list_fully_supporteds_for_expression(expression_id) do
    query = from ep in FullySupported, where: ep.expression_id == ^expression_id
    Repo.all(query)
  end

  @doc """
  Returns the list of fully_supporteds for a particular group.

  ## Examples

      iex> list_fully_supporteds_for_group(group_id)
      [%FullySupported{}, ...]

  """
  def list_fully_supporteds_for_group(group_id) do
    query = from ep in FullySupported, where: ep.group_id == ^group_id
    Repo.all(query)
  end

  @doc """
  Gets a single fully_supported.

  Raises `Ecto.NoResultsError` if the FullySupported does not exist.

  ## Examples

      iex> get_fully_supported!(123)
      %FullySupported{}

      iex> get_fully_supported!(456)
      ** (Ecto.NoResultsError)

  """
  def get_fully_supported!(id), do: Repo.get!(FullySupported, id)

  @doc """
  Creates a fully_supported.

  ## Examples

      iex> create_fully_supported(%{field: value})
      {:ok, %FullySupported{}}

      iex> create_fully_supported(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_fully_supported(attrs \\ %{}) do
    %FullySupported{}
    |> FullySupported.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a fully_supported.

  ## Examples

      iex> delete_fully_supported(fully_supported)
      {:ok, %FullySupported{}}

      iex> delete_fully_supported(fully_supported)
      {:error, %Ecto.Changeset{}}

  """
  def delete_fully_supported(%FullySupported{} = fully_supported) do
    Repo.delete(fully_supported)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fully_supported changes.

  ## Examples

      iex> change_fully_supported(fully_supported)
      %Ecto.Changeset{data: %FullySupported{}}

  """
  def change_fully_supported(%FullySupported{} = fully_supported, attrs \\ %{}) do
    FullySupported.changeset(fully_supported, attrs)
  end

  @doc """
  Returns whether or not this expression is fully supported for the given group

  ## Examples

      iex> is_expression_fully_supported(expression, group_id)
      true

  """
  def is_expression_fully_supported(expression, group_id) do
    query =
      if is_nil(group_id) do
        from s in Support,
          where: s.expression_id == ^expression.id
      else
        from s in Support,
          where:
            s.expression_id == ^expression.id and
              s.for_group_id == ^group_id
      end

    subscription_count =
      ExpressionSubscriptions.count_expression_subscriptions_for_expression(group_id)

    quorum = Kernel.round(SeekingSupports.calculate_sortition_size(subscription_count) * 0.51)

    aggregate = Repo.aggregate(query, :sum, :support)

    case aggregate do
      nil ->
        false

      _ ->
        total_support = Kernel.round(aggregate)
        total_support >= quorum
    end
  end
end
