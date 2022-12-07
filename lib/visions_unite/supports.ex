defmodule VisionsUnite.Supports do
  @moduledoc """
  The Supports context.
  """

  import Ecto.Query, warn: false
  alias VisionsUnite.Repo

  alias VisionsUnite.Accounts
  alias VisionsUnite.Supports.Support
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Expressions
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.FullySupporteds

  @doc """
  Returns the list of support.

  ## Examples

      iex> list_support()
      [%Support{}, ...]

  """
  def list_support do
    Repo.all(Support)
  end

  @doc """
  This function returns the list of supports > 0 for a given expression.

  ## Examples

      iex> list_supports_for_expression(expression)
      [%Support{} ...]

  """
  def list_supports_for_expression(expression) do
    query =
      from s in Support,
        where:
          s.expression_id == ^expression.id and
            s.support > 0.0

    Repo.all(query)
  end

  @doc """
  This function returns the list of all supports (even < 0) for a given expression.

  ## Examples

      iex> list_all_supports_for_expression(expression)
      [%Support{} ...]

  """
  def list_all_supports_for_expression(expression) do
    query =
      from s in Support,
        where: s.expression_id == ^expression.id

    Repo.all(query)
  end

  @doc """
  This function returns the count of supports for a given expression.

  ## Examples

      iex> count_support_for_expression(expression)
      83

  """
  def count_support_for_expression(expression) do
    query =
      from s in Support,
        where:
          s.expression_id == ^expression.id and
            s.support > 0.0

    Repo.aggregate(query, :count)
  end

  @doc """
  This function returns the count of supports for a given expression for a given group.

  ## Examples

      iex> count_support_for_expression_for_group(expression, group_id)
      83

  """
  def count_support_for_expression_for_group(expression, nil),
    do: count_support_for_expression(expression)

  def count_support_for_expression_for_group(expression, group_id) do
    query =
      from s in Support,
        where:
          s.expression_id == ^expression.id and
            s.support > 0.0 and
            s.for_group_id == ^group_id

    Repo.aggregate(query, :count)
  end

  @doc """
  Gets a single support.

  Raises `Ecto.NoResultsError` if the Support does not exist.

  ## Examples

      iex> get_support!(123)
      %Support{}

      iex> get_support!(456)
      ** (Ecto.NoResultsError)

  """
  def get_support!(id), do: Repo.get!(Support, id)

  @doc """
  Creates a support.

  ## Examples

      iex> create_support(%{field: value})
      {:ok, %Support{}}

      iex> create_support(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_support(attrs \\ %{}) do
    for_group_id = attrs.for_group_id
    expression_id = attrs.expression_id
    user_id = attrs.user_id
    expression = Expressions.get_expression!(expression_id)
    user = Accounts.get_user!(user_id)

    existing_seeking_support =
      SeekingSupports.get_seeking_support_for_expression_and_user_for_group!(
        expression,
        user,
        for_group_id
      )

    if !is_nil(existing_seeking_support) do
      support =
        %Support{}
        |> Support.changeset(attrs)
        |> Repo.insert()

      # Remove the existing seeking support from the user that just clicked
      SeekingSupports.delete_seeking_support(existing_seeking_support)

      # Seeking Support has been deleted.... now we check for support
      subscriber_counts_maps = ExpressionSubscriptions.get_subscriber_counts_maps(expression)

      quorum_maps =
        Enum.map(subscriber_counts_maps, fn subscriber_counts_map ->
          group_id =
            subscriber_counts_map
            |> Map.keys()
            |> List.first()

          subscribers_count = Map.get(subscriber_counts_map, group_id)

          sortition_num = SeekingSupports.calculate_sortition_size(subscribers_count)

          quorum_size = Kernel.round(sortition_num * 0.51)

          %{group_id => quorum_size}
        end)

      Enum.each(quorum_maps, fn quorum_map ->
        group_id =
          quorum_map
          |> Map.keys()
          |> List.first()

        if FullySupporteds.is_expression_fully_supported(expression, group_id) do
          # if expression has been fully supported BY THIS GROUP, remove ALL seeking support
          # FOR THIS GROUP because the goal has already been reached FOR THIS GROUP

          SeekingSupports.delete_all_seeking_support_for_expression_with_group(
            expression,
            group_id
          )

          # also, set the expression as fully supported (by creating some FullySupported rows for each group_id), because more users will screw up whether or not it is indeed

          FullySupporteds.create_fully_supported(%{
            expression_id: expression.id,
            group_id: group_id
          })

          # then broadcast the support for all users
          VisionsUniteWeb.SharedPubSub.broadcast(
            {:ok, expression},
            :expression_fully_supported,
            "support"
          )
        end
      end)

      # broadcast to everyone that an expression has been supported, regardless
      # of whether or not it is fully supported
      VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :expression_supported, "support")

      # return the support
      support
    end
  end

  @doc """
  Updates a support.

  ## Examples

      iex> update_support(support, %{field: new_value})
      {:ok, %Support{}}

      iex> update_support(support, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_support(%Support{} = support, attrs) do
    support
    |> Support.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a support.

  ## Examples

      iex> delete_support(support)
      {:ok, %Support{}}

      iex> delete_support(support)
      {:error, %Ecto.Changeset{}}

  """
  def delete_support(%Support{} = support) do
    Repo.delete(support)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking support changes.

  ## Examples

      iex> change_support(support)
      %Ecto.Changeset{data: %Support{}}

  """
  def change_support(%Support{} = support, attrs \\ %{}) do
    Support.changeset(support, attrs)
  end
end
