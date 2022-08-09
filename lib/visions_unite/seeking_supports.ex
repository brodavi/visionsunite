defmodule VisionsUnite.SeekingSupports do

  @moduledoc """
  The SeekingSupport context.
  """

  import Ecto.Query, warn: false

  alias VisionsUnite.Repo

  alias VisionsUnite.Accounts
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.SeekingSupports.SeekingSupport

  @doc """
  Returns the seeking support for a given expression and user.

  ## Examples

      iex> get_seeking_support_for_expression_and_user!(expression, user)
      [%SeekingSupport{}, ...]

  """
  def get_seeking_support_for_expression_and_user!(expression, user) do
    query =
      from e in SeekingSupport,
      where: e.expression_id == ^expression.id and e.user_id == ^user.id

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
      from se in SeekingSupport,
      where: se.expression_id == ^expression.id
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

    subscribers_map =
      get_subscribers_map(expression)

    sortitions_map =
      get_sortition_map(subscribers_map, expression)
    #
    # this is the "filtered" set of map of expression_ids and users, randomly
    # selected from the subscribers to be the sortition group for that linked expression
    #

    # NOTE: sortitionas_map has sortitions that are NOT unique. One user could be in multiple
    #       sortitions
    #
    # TODO seek support one at a time, according to "temperature?", not all at once
    #      here we just create the seeking support... we don't have to actually display
    #      it on anyone's screen until it is time.... but then we need some sense of
    #      "next in line"? also, when do we display the request for the "next in line"?
    #      I guess we don't really need "next in line" ... just find the seeking_supports,
    #      not in any order, but whatever just pick "next in line" at random

    # Seek support for each linked expression group
    sortitions_map
    |> Enum.each(fn sortition_group ->

      group_id =
        elem(sortition_group, 0)

      elem(sortition_group, 1)
      |> Enum.each(fn subscriber ->
        create_seeking_support(%{
          expression_id: expression.id,
          user_id: subscriber,
          for_group_id: group_id
        })
      end)
    end)

    # TODO maybe don't actually display it on anyone's screen until it is time?....
    VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :sortition_created, "sortitions")
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
      from se in SeekingSupport,
      where: se.expression_id == ^expression.id
    Repo.delete_all(query)
  end

  #
  # This function gets the subscriber lists for an expression
  #
  # This means it will follow all linked expressions (if there are any) and build a list of lists
  # of users that subscribe to the linked expressions
  #
  # If the expression does not have any linked expressions, this returns an empty map!!!!
  # and can thus be interpreted as a "root expression"
  #
  # TODO this really should go into ExpressionSubscriptions!!!!!!!!!!!!!!!!!
  #
  # NOTE: the "group_by" returns a MAP!!!!!!!!!!! so the return of this function will be %{} or
  # %{5 => [1,2,3], 6 => [7,5,4], ...}
  #
  def get_subscribers_map(expression) do
    IO.puts "----------------------- SeekingSupports.get_subscribers_map expression : #{inspect expression} ---------------------------------------"
    subscribers_map =
      if Enum.count(expression.expression_linkages) == 0 do
        user_ids =
          Accounts.list_users
          |> Enum.filter(& &1.id != expression.author_id)
          |> Enum.map(& &1.id)

        %{nil => user_ids}
      else
        subscribers_list =
          expression.expression_linkages
          |> Enum.map(fn expression_link ->
            # TODO this probably needs to be a single join query
            ExpressionSubscriptions.list_expression_subscriptions_for_expression(expression_link.expression_id)
            |> Enum.filter(& &1.user_id != expression.author_id)
            |> Enum.map(& &1.user_id)
          end)

        IO.puts "subscribers list: #{inspect subscribers_list} -------------------------------------"

        subscribers_map =
          if Enum.count(Enum.at(subscribers_list, 0)) == 0 do
            # Subscribers list is STILL 0 (there are linked expressions, but still nobody is subscribed)
            # so just create the root expression subscribers map consisting of everyone
            user_ids =
              Accounts.list_users
              |> Enum.filter(& &1.id != expression.author_id)
              |> Enum.map(& &1.id)

            %{nil => user_ids}
          else
            subscribers_list
            |> Enum.group_by(& &1.expression_id)
          end

        IO.puts "subscribers map: #{inspect subscribers_map} -------------------------------------"

        subscribers_map
      end

    subscribers_map
  end

  #
  # This function randomly picks a sortition from a subscriber group
  #
  # NOTE: list of subscribers has this shape:
  #
  # %{ 32 => [ 24, 19, ...  ], 43 => [ 84, 3, ...  ], ... }
  #
  def get_sortition_map(subscribers_map, expression) do
    if Enum.count(Map.keys(subscribers_map)) == 0 do
      # this is a root expression... pull sortition list from group of all users
      everyone =
        Accounts.list_users_ids()
        |> Enum.filter(& &1 != expression.author_id)

      sortition_num = calculate_sortition_size(Enum.count(everyone))

      # Random sortition is fine for root expressions
      %{nil => Enum.take_random(everyone, Kernel.round(sortition_num))}
    else
      Map.keys(subscribers_map)
      |> Enum.map(fn group_id ->
        subscribers =
          Map.get(subscribers_map, group_id)
          |> Enum.filter(& &1 != expression.author_id)

        # Get the sortition for each group separately
        sortition_num = calculate_sortition_size(Enum.count(subscribers))

        # NOTE this could have multiple instances of the same user
        {group_id, Enum.take_random(subscribers, Kernel.round(sortition_num))}
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

