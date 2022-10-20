defmodule VisionsUnite.Expressions.Expression do
  use Ecto.Schema
  import Ecto.Changeset
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.ExpressionLinkages.ExpressionLinkage
  alias VisionsUnite.Expressions
  alias VisionsUnite.ExpressionSubscriptions
  alias VisionsUnite.FullySupporteds
  alias VisionsUnite.FullySupporteds.FullySupported
  alias VisionsUnite.SeekingSupports
  alias VisionsUnite.Supports

  schema "expressions" do
    field :title, :string
    field :body, :string
    field :temperature, :float

    belongs_to :author, User
    has_many :expression_linkages, ExpressionLinkage
    has_many :fully_supporteds, FullySupported

    has_many :linked_expressions, through: [:expression_linkages, :link]

    timestamps()
  end

  @doc false
  def changeset(expression, attrs) do
    expression
    |> cast(attrs, [:title, :body, :temperature, :author_id])
    |> validate_required([:title, :body, :author_id])
  end

  def annotate_with_group_data(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_group_data(expression)
    end)
  end

  def annotate_with_group_data(expression) when is_map(expression) do

    #
    # TODO this should probably rely on expression.group_count!
    #      instead of hitting the DB again
    #

    expression =
      expression
      |> Expressions.preload_links()

    linkages_or_root =
      if Enum.count(expression.expression_linkages) != 0 do
        expression.expression_linkages
      else
        # This is hacky... there has to be a better way
        [%{link: %{id: nil, title: "all"}}]
      end

    # annotate with link data
    groups =
      linkages_or_root
      |> Enum.map(fn group ->
        subscriber_count =
          ExpressionSubscriptions.count_expression_subscriptions_for_expression(group.link.id)
        quorum_count =
          Kernel.round(SeekingSupports.calculate_sortition_size(subscriber_count) * 0.51)
        support_count =
          Supports.count_support_for_expression_for_group(expression, group.link.id)

        Map.merge(
          group,
          %{
            subscriber_count: subscriber_count,
            quorum_count: quorum_count,
            support_count: support_count
          }
        )
      end)

    # okay... if expression_linkages is [], then this is a
    # root expression, and it will not populate with data..

    Map.merge(expression, %{ groups: groups })
  end

  def annotate_with_linked_expressions(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_linked_expressions(expression)
    end)
  end

  def annotate_with_linked_expressions(expression) when is_map(expression) do

    #
    # TODO this should probably rely on expression.group_count!
    #      instead of hitting the DB again
    #

    expression =
      expression
      |> Expressions.preload_links()

    # annotate with linked expression data
    linked_expressions =
      expression.expression_linkages
      |> Enum.map(fn linked_expression ->
        subscriber_count =
          ExpressionSubscriptions.count_expression_subscriptions_for_expression(linked_expression.link.id)
        quorum_count =
          Kernel.round(SeekingSupports.calculate_sortition_size(subscriber_count) * 0.51)
        support_count =
          Supports.count_support_for_expression(linked_expression.link)

        Map.merge(
          linked_expression,
          %{
            subscriber_count: subscriber_count,
            quorum_count: quorum_count,
            support_count: support_count
          }
        )
      end)

    Map.merge(expression, %{ linked_expressions: linked_expressions })
  end

  def annotate_with_supports(expressions) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_supports(expression)
    end)
  end

  def annotate_with_supports(expression) when is_map(expression) do
    Map.merge(expression, %{
      supports: Supports.list_supports_for_expression(expression)
    })
  end

  def annotate_with_fully_supporteds(expressions, user_id) when is_list(expressions) do
    expressions
    |> Enum.map(fn expression ->
      annotate_with_fully_supporteds(expression, user_id)
    end)
  end

  def annotate_with_fully_supporteds(expression, user_id) when is_map(expression) do
    fully_supporteds =
      FullySupporteds.list_fully_supporteds_for_expression_and_user(expression.id, user_id)
      |> Enum.map(fn fs ->
        Expressions.get_expression_title(fs.group_id)
      end)

    Map.merge(expression, %{
      fully_supporteds: fully_supporteds
    })
  end
end

