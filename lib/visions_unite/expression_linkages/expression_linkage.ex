defmodule VisionsUnite.ExpressionLinkages.ExpressionLinkage do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Expressions.Expression

  schema "expression_linkages" do
    belongs_to :expression, Expression
    belongs_to :link, Expression

    timestamps()
  end

  @doc false
  def changeset(expression_linkage, attrs) do
    expression_linkage
    |> cast(attrs, [:expression_id, :link_id])
    |> validate_required([:expression_id, :link_id])
    |> unique_constraint(:unique_link, name: :unique_link)
  end
end
