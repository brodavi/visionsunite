defmodule VisionsUnite.ExpressionParentages.ExpressionParentage do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Expressions.Expression

  schema "expression_parentages" do
    belongs_to :expression, Expression
    belongs_to :parent, Expression

    timestamps()
  end

  @doc false
  def changeset(expression_parentage, attrs) do
    expression_parentage
    |> cast(attrs, [:expression_id, :parent_id])
    |> validate_required([:expression_id, :parent_id])
  end
end

