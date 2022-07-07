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
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.SeekingSupports.SeekingSupport

  @doc """
  Returns the seeking support for a given expression and user.

  ## Examples

      iex> get_seeking_support_for_expression_and_user!(expression, user)
      [%SeekingSupport{}, ...]

  """
  def get_seeking_support_for_expression_and_user!(expression, user) do
    query = from e in SeekingSupport, where: e.expression_id == ^expression.id and e.user_id == ^user.id
    Repo.one(query)
  end

  @doc """
  Returns the list of support sought for a given expression.

  ## Examples

      iex> list_support_sought_for_expression(%Expression{})
      [3, 25, ...]

  """
  def list_support_sought_for_expression(expression) do
    query = from se in SeekingSupport, where: se.expression_id == ^expression.id
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
  def seek_supporters({:ok, expression}) do
    users = Repo.all(User)
            |> Enum.filter(fn user ->
              user.id != expression.author_id
            end)

    sortition_num = get_sortition_num()

    sortition =
      Enum.take_random(users, Kernel.round(sortition_num))
      |> Enum.map(& &1.id)

    sortition
    |> Enum.each(fn user_id ->
      create_seeking_support(%{
        expression_id: expression.id,
        user_id: user_id
      })
    end)

    # The reason we're putting this task in the supervisor is that when the expression
    #   is created, the sortition gets called. Then seeking supports is called. Then
    #   without the supervisor, the :sortition_created message is broadcast... and
    #   THEN, in the calling code (form_component) the expression parentage is
    #   created. So by putting this in the supervisor, it just waits 1 second before
    #   finally sending the broadcast.
    Task.Supervisor.start_child(VisionsUnite.MySupervisor, fn ->
      :timer.sleep(1000)
      VisionsUniteWeb.SharedPubSub.broadcast({:ok, expression}, :sortition_created, "sortitions")
    end)

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
    query = from se in SeekingSupport, where: se.expression_id == ^expression.id
    Repo.delete_all(query)
  end

  defp get_sortition_num do
    users_count = Accounts.count_users()

    case @sortition_percent_or_fixed do
      "PERCENT" ->
        percent = @sortition_percent

        # If the group is large enough, then ignore sortition percentages,
        # and just use the statistical relevance via https://surveysystem.com/sscalc.htm
        Kernel.min(users_count * percent * 0.01, @sortition_max)
      "FIXED" ->
        @sortition_fixed
    end
  end

  def get_quorum_num do
    case @quorum_percent_or_fixed do
      "PERCENT" ->
        percent = @quorum_percent

        sortition_num = get_sortition_num()
        Kernel.round(sortition_num * percent * 0.01)
      "FIXED" ->
        @quorum_fixed
    end
  end
end

