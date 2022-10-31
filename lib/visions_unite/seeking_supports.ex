defmodule VisionsUnite.SeekingSupports do

  @moduledoc """
  The SeekingSupport context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Accounts
  alias VisionsUnite.ExpressionLinkages
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.SeekingSupports.SeekingSupport

  @doc """
  Returns the seeking support for a given expression and user and group.

  ## Examples

      iex> get_seeking_support_for_expression_and_user_for_group!(expression, user, for_group)
      [%SeekingSupport{}, ...]

  """
  def get_seeking_support_for_expression_and_user_for_group!(expression, user, for_group_id) do
    query =
      if for_group_id == "" do
        from ss in SeekingSupport,
        where: ss.expression_id == ^expression.id and ss.user_id == ^user.id and is_nil(ss.for_group_id)
      else
        from ss in SeekingSupport,
        where: ss.expression_id == ^expression.id and ss.user_id == ^user.id and ss.for_group_id == ^for_group_id
      end

    Repo.one(query)
  end

  @doc """
  Returns the list of support sought for a given user.

  ## Examples

      iex> list_support_sought_for_user(user_id)
      [3, 25, ...]

  """
  def list_support_sought_for_user(user_id) do
    query =
      from ss in SeekingSupport,
      where: ss.user_id == ^user_id
    Repo.all(query)
  end

  @doc """
  Returns the list of support sought for a given expression.

  ## Examples

      iex> list_support_sought_for_expression(%Expression{})
      [3, 25, ...]

  """
  def list_support_sought_for_expression(expression) do
    query =
      from ss in SeekingSupport,
      where: ss.expression_id == ^expression.id
    Repo.all(query)
  end

  @doc """
  Creates a seeking_support.

  ## Examples

      iex> create_seeking_support(%{field: value})
      {:ok, %SeekingSupport{}}

      iex> create_seeking_support(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_seeking_support(attrs \\ %{}) do
    %SeekingSupport{}
    |> SeekingSupport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets some subset of users in the system and seeks support from them for the given expression

  ## Examples

      iex> seek_supporters(%Expression{})
      [%User{}, ...]
  """
  def seek_supporters(expression) do

    subscriptions_maps =
      ExpressionSubscriptions.get_subscribers_maps(expression)

    sortitions_maps =
      get_sortition_maps(subscriptions_maps, expression)

    #
    # this is the "filtered" set of map of expression_ids and users, randomly
    # selected from the subscribers to be the sortition group for that linked expression
    #

    # NOTE: sortitions_map has sortitions that are NOT unique.
    # One user could be in multiple sortitions

    # Seek support for each linked expression group
    sortitions_maps
    |> Enum.each(fn sortition_group ->
      group_id =
        List.first(Map.keys(sortition_group))

      Map.get(sortition_group, group_id)
      |> Enum.each(fn subscriber ->
        create_seeking_support(%{
          expression_id: expression.id,
          user_id: subscriber,
          for_group_id: group_id
        })
      end)
    end)

    VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :sortition_created, "sortitions")

    sortitions_maps
  end

  @doc """
  Deletes a seeking_support.

  ## Examples

      iex> delete_seeking_support(seeking_support)
      {:ok, %SeekingSupport{}}

      iex> delete_seeking_support(seeking_support)
      {:error, %Ecto.Changeset{}}

  """
  def delete_seeking_support(%SeekingSupport{} = seeking_support) do
    Repo.delete(seeking_support)
  end

  @doc """
  Deletes all seeking_support for a given expression.

  ## Examples

      iex> delete_all_seeking_support_for_expression(expression)
      {:ok}

  """
  def delete_all_seeking_support_for_expression(%Expression{} = expression) do
    query =
      from ss in SeekingSupport,
      where: ss.expression_id == ^expression.id
    Repo.delete_all(query)
  end

  @doc """
  Deletes all seeking_support for a given expression and group.

  ## Examples

      iex> delete_all_seeking_support_for_expression_with_group(expression, group_id)
      {:ok}

  """
  def delete_all_seeking_support_for_expression_with_group(%Expression{} = expression, nil) do
    query =
      from ss in SeekingSupport,
      where: ss.expression_id == ^expression.id
    Repo.delete_all(query)
  end

  def delete_all_seeking_support_for_expression_with_group(%Expression{} = expression, group_id) do
    query =
      from ss in SeekingSupport,
      where: ss.expression_id == ^expression.id and
    ss.for_group_id == ^group_id

    Repo.delete_all(query)
  end

  #
  # This function randomly picks a sortition from each subscriber group
  #
  def get_sortition_maps(subscriptions_maps, expression) do
    first_key =
      subscriptions_maps
      |> List.first()
      |> Map.keys()
      |> List.first()

    linkages =
      ExpressionLinkages.list_expression_linkages_for_expression(expression.id)

    if is_nil(first_key) and Enum.count(linkages) == 0 do
      # this is a root expression...
      # pull sortition list from group of all users
      everyone =
        Accounts.list_users_ids()
        |> Enum.filter(& &1 != expression.author_id)

      sortition_num =
        everyone
        |> Enum.count()
        |> calculate_sortition_size()

      [%{nil => Enum.take_random(everyone, Kernel.round(sortition_num))}]
    else
      Enum.map(subscriptions_maps, fn subscription_map ->

        if subscription_map == %{nil: nil} do
          %{nil => []}
        else
          group_id =
            subscription_map
            |> Map.keys()
            |> List.first()

          subscribers_list =
            Map.get(subscription_map, group_id)
            |> Enum.filter(& &1 != expression.author_id)
            |> Enum.map(& &1.user_id)

          # Get the sortition for each group separately
          sortition_num =
            subscribers_list
            |> Enum.count()
            |> calculate_sortition_size()

          # NOTE this could have multiple instances of the same user
          %{group_id => Enum.take_random(subscribers_list, Kernel.round(sortition_num))}
        end
      end)
    end
  end

  #
  # This function gets the sortition size for a given population number
  #
  # The sortition is also known as the sample size, which is calculated by a formula
  # from statistics.
  #
  # If an expression is a root expression, the sortition is calculated against the entire
  # user base. If an expression is linked with other expressions, the sortition is
  # calculated per-linked-expression. This means quorum could be reached on one
  # linked expression's group but not another.
  #

  def calculate_sortition_size(0), do: 0
  def calculate_sortition_size(group_count) do

    ## Calculating Sample Size with Finite Population from https://www.youtube.com/watch?v=gLD4tENS82c
    ## c = Confidence Level = 95%
    ## p = Population Proportion = 0.5 (most conservative)
    ## e = Margin of Error aka Confidence Interval = 0.04 (4%)
    ## pop = Population Size = 2500
    ## 
    ## a_div_2 = Alpha divided by 2 = (1-c)/2 = 0.025
    ## z = Z-Score = norm.s.inv(1-a_div_2) = 1.96
    ## 
    ## numerator = (z^2) * (p*(1-p))/(e^2) = 600.23
    ## denominator = 1 + (z^2) * (p*(1-p))/(e^2*pop) = 1.24
    ## Sample Size = numerator/denominator = 484
    ##

    p = 0.5
    e = 0.04
    pop = if group_count == %{} do Accounts.count_users() else group_count end
    z = 1.96 # For 95% confidence level

    numerator = Float.pow(z, 2) * (p * (1 - p)) / Float.pow(e, 2)

    denominator = 1 + Float.pow(z, 2) * (p * (1 - p)) / (Float.pow(e, 2) * pop)

    Kernel.round(numerator / denominator)
  end
end

