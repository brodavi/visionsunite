defmodule VisionsUnite.SeekingSupports do

  # some app configurations
  @sortition_percent_or_fixed System.get_env("SORTITION_PERCENT_OR_FIXED")
  @sortition_percent String.to_integer(System.get_env("SORTITION_PERCENT"))
  @sortition_fixed String.to_integer(System.get_env("SORTITION_FIXED"))
  @sortition_max 384 # see https://surveysystem.com/sscalc.htm
  @quorum_percent_or_fixed System.get_env("QUORUM_PERCENT_OR_FIXED")
  @quorum_percent String.to_integer(System.get_env("QUORUM_PERCENT"))
  @quorum_fixed String.to_integer(System.get_env("QUORUM_FIXED"))

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
    subscribers =
      expression.parents
      |> Enum.map(fn parent_expression ->
        ExpressionSubscriptions.list_expression_subscriptions_for_expression(parent_expression)
        # this returns [%{expression_id: 43, user_id: 24}, ...] , etc
        |> Enum.filter(& &1.user_id)
        # this returns [%{user_id: 24}, ...] , etc
        |> Enum.filter(& &1 != expression.author_id)
      end)

    # this returns...
    #
    # [
    #  [
    #   %{user_id: 24}, ...
    #  ],
    #  [
    #   %{user_id: 84}, ...
    #  ],
    # ]
    #
    # ... which is the set of sets of users subscribed to each parent

    sortition =
      if subscribers == [] do

        # no linked expressions, so just get all users... this is a "root expression"
        everyone =
          Accounts.list_users_ids()
          |> Enum.filter(& &1 != expression.author_id)

        sortition_num = get_sortition_num(Enum.count(everyone))

        # Random sortition is fine for root expressions
        Enum.take_random(everyone, Kernel.round(sortition_num))

      else

        subscribers
        |> Enum.map([], fn group ->

          group =
            group
            |> Enum.filter(& &1 != expression.author_id)

          # Get the sortition for each group separately
          sortition_num = get_sortition_num(Enum.count(group))

          # TODO get sortition correctly for each group
          Enum.take_random(group, Kernel.round(sortition_num))

        end)

      end
      # NOTE: the variable `sortition` at this point has a list of users... and NOT unique.

    # TODO seek support one at a time, according to temperature?, not all at once
    #  HOWEVER! this just creates the seeking support... we don't have to
    #  actually display it on anyone's screen until it is time....
    #  but then we need some sense of "next in line"?

    if is_list(sortition) do
      # Seek support for each linked expression group
      sortition
      |> Enum.each(fn sortition_group ->
        sortition_group
        |> Enum.each(fn user_id ->
          create_seeking_support(%{
            expression_id: expression.id,
            user_id: user_id
          })
        end)
      end)
    else
      # Seek support from everyone in the system
      sortition
      |> Enum.each(fn user_id ->
        create_seeking_support(%{
          expression_id: expression.id,
          user_id: user_id
        })
      end)
    end

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
  # This function gets the sortition for an expression
  #
  # The sortition is also known as the sample size, which is calculated by a formula
  # from statistics.
  #
  # The quorum is simply the simple majority of the sortition (51%)
  #
  # If an expression is a root expression, the sortition is calculated against the entire
  # user base. If an expression is linked with other expressions, the sortition is
  # calculated per-linked-expression. This means quorum could be reached on one
  # linked expression's group but not another.
  #

  def get_sortition_num(group_count) do

    ## Calculating Sample Size with Finite Population from https://www.youtube.com/watch?v=gLD4tENS82c
    ## 
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
    ## 
    ## Sample Size = numerator/denominator = 484
    ##

    p = 0.5
    e = 0.04
    pop = group_count
    z = 1.96 # For 95% confidence level

    numerator = Float.pow(z, 2) * (p * (1 - p)) / Float.pow(e, 2)
    denominator = 1 + Float.pow(z, 2) * (p * (1 - p)) / (Float.pow(e, 2) * pop)

    numerator / denominator
  end

  #
  # This function returns the quorum necessary for an expression to be fully supported.
  # The quorum is a simple majority 51% or *0.51 of the sortition size.
  #
  def get_quorum_num_for_expression(expression) do
    if Enum.count(expression.parents) == 0 do
      Kernel.round(get_sortition_num(Accounts.count_users() - 1) * 0.51) # -1 to account for author
    else
      Enum.map(expression.parents, fn parent_title, acc ->
        parent_group_count =
          ExpressionSubscriptions.count_expression_subscriptions_for_expression_by_name(parent_title)
        Kernel.round(get_sortition_num(parent_group_count - 1) * 0.51) # -1 to account for author
      end)
    end
  end
end

