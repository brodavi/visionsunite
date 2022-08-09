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
  This function returns the list of supports for a given expression.

  ## Examples

      iex> list_supports_for_expression(expression)
      83

  """
  def list_supports_for_expression(expression) do
    query = from e in Support,
      where: e.expression_id == ^expression.id

    Repo.all(query)
  end

  @doc """
  This function returns the count of supports for a given expression.

  ## Examples

      iex> count_support_for_expression(expression)
      83

  """
  def count_support_for_expression(expression) do
    query = from e in Support,
      where: e.expression_id == ^expression.id and e.support > 0.0

    Repo.aggregate(query, :count)
  end

  @doc """
  Returns the latest support for a given expression.

  ## Examples

      iex> get_latest_support_for_expression(expression)
      %Support{}

      iex> get_latest_support_for_expression(expression)
      nil

  """
  def get_latest_support_for_expression(expression) do
    query = from e in Support,
      where: e.expression_id == ^expression.id and e.support >= 0.0,
      order_by: e.inserted_at,
      limit: 1

    Repo.all(query)
    |> Enum.map(& &1.inserted_at)
    |> List.first()
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
    support =
      %Support{}
      |> Support.changeset(attrs)
      |> Repo.insert()

    {:ok, %Support{ expression_id: expression_id, user_id: user_id }} = support

    expression = Expressions.get_expression!(expression_id)
    user = Accounts.get_user!(user_id)

    # Remove the existing seeking support from the user that just clicked
    existing_seeking_support =
      SeekingSupports.get_seeking_support_for_expression_and_user!(expression, user)

    SeekingSupports.delete_seeking_support(existing_seeking_support)

    # Seeking Support has been deleted.... now we check for support
    subscribers_map =
      SeekingSupports.get_subscribers_map(expression)

    quorum_map =
      Map.keys(subscribers_map)
      |> Map.new(fn group_id ->
        sortition_size =
          subscribers_map
          |> Map.get(group_id)
          |> Enum.count()
          |> SeekingSupports.calculate_sortition_size()

        quorum_size = Kernel.round(sortition_size * 0.51)

        {group_id, quorum_size}
      end)

    Map.keys(quorum_map)
    |> Enum.each(fn group_id ->

      if Expressions.is_expression_fully_supported(expression, Map.get(quorum_map, group_id)) do

        # if expression has been fully supported, remove ALL seeking support
        # because the goal has already been reached
        SeekingSupports.delete_all_seeking_support_for_expression(expression)

        # also, mark the expression as fully supported, because more users will screw up whether or not it is indeed
        Expressions.mark_fully_supported(expression)

        # then broadcast the support for all users
        VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :expression_fully_supported, "support")
      end
    end)

    # broadcast to everyone that an expression has been supported, regardless
    # of whether or not it is fully supported
    VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :expression_supported, "support")

    # return the support
    support
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

