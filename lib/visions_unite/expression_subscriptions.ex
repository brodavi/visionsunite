defmodule VisionsUnite.ExpressionSubscriptions do
  @moduledoc """
  The ExpressionSubscriptions context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Accounts
  alias VisionsUnite.ExpressionLinkages
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

      iex> count_expression_subscriptions_for_expression(482)
      230

  """
  def count_expression_subscriptions_for_expression(nil) do
    Accounts.count_users()
  end

  def count_expression_subscriptions_for_expression(expression) when is_map(expression) do
    query =
      from es in ExpressionSubscription,
      where: es.expression_id == ^expression.id

    Repo.aggregate(query, :count)
  end

  def count_expression_subscriptions_for_expression(expression_id) when is_number(expression_id) do
    query = from es in ExpressionSubscription,
      join: e in Expression,
      on: e.id == es.expression_id,
      where: e.id == ^expression_id

    Repo.aggregate(query, :count)
  end

  @doc """
  Returns the list of expression_subscriptions for a particular expression.

  ## Examples

      iex> list_expression_subscriptions_for_expression(428)
      [%ExpressionSubscription{}, ...]

      iex> list_expression_subscriptions_for_expression(%Expression{})
      [%ExpressionSubscription{}, ...]
  """
  def list_expression_subscriptions_for_expression(expression_id) when is_number(expression_id) do
    query = from es in ExpressionSubscription,
      where: es.expression_id == ^expression_id

    Repo.all(query)
  end

  def list_expression_subscriptions_for_expression(expression) when is_map(expression) do
    query = from es in ExpressionSubscription,
      where: es.expression_id == ^expression.id and
             es.subscribe == true

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
    query =
      from es in ExpressionSubscription,
      where: es.user_id == ^user_id
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

  @doc """
  This function gets the subscriber lists for an expression

  This means it will follow all linked expressions (if there are any) and build a map of expressions and lists of users that subscribe to those linked expressions

  If the expression does not have any linked expressions, this returns an empty map and can thus be interpreted as a "root expression"

  ## Examples

      iex> get_subscribers_maps(root_expression)
      [%{nil => nil}]

      iex> get_subscribers_maps(expression_with_linked_expressions)
      [%{5 => [1,2,3]}, %{6 => [7,5,4]}, ...]
  """
  def get_subscribers_maps(expression) do
    expression_linkages =
      ExpressionLinkages.list_expression_linkages_for_expression(expression.id)

    if Enum.count(expression_linkages) == 0 do
      [%{nil => nil}] # note the sortition is pulled in SeekingSupports
    else
      subscribers_lists =
        expression_linkages
        |> Enum.map(fn expression_linkage ->
          list_expression_subscriptions_for_expression(expression_linkage.link_id)
          |> Enum.filter(& &1.user_id != expression.author_id)
        end)

      if Enum.count(Enum.at(subscribers_lists, 0)) == 0 do
        # Subscribers list is STILL 0 (there are linked expressions, but still nobody is subscribed)
        [%{nil => nil}] # note the sortition is pulled in SeekingSupports
      else
        subscribers_lists
        |> Enum.map(fn subscriber_list ->
          subscriber_list
          |> Enum.group_by(& &1.expression_id)
        end)
      end
    end
  end

  @doc """
  This function gets only the aggregate counts, not the actual users of the map of subscribers for this expression and its linked_expressions

  ## Examples

      iex> get_subscriber_counts_maps(new_root_expression)
      [%{}]

      iex> get_subscriber_counts_maps(expression_with_linked_expressions)
      [%{5 => 48}, %{6 => 28}, ...]
  """
  def get_subscriber_counts_maps(expression) do
    expression_linkages =
      ExpressionLinkages.list_expression_linkages_for_expression(expression.id)

    if Enum.count(expression_linkages) == 0 do
      # No linked expressions... "subscribers" is everyone
      users_count =
        Accounts.count_users() -1 # Minus one to account for author

      [%{nil => users_count}]
    else
      expression_linkages
      |> Enum.map(fn expression_linkage ->
        count = count_expression_subscriptions_for_expression(expression_linkage.link_id)
        %{expression_linkage.link_id => count}
      end)
    end
  end
end

