defmodule VisionsUnite.Expressions.Expression do
  use Ecto.Schema
  import Ecto.Changeset
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.ExpressionParentages.ExpressionParentage

  schema "expressions" do
    field :body, :string
    field :temperature, :float

    belongs_to :author, User
    has_many :expression_parentages, ExpressionParentage
    has_many :parents, through: [:expression_parentages, :parent]

    timestamps()
  end

  @doc false
  def changeset(expression, attrs) do
    expression
    |> cast(attrs, [:body, :temperature, :author_id])
    |> validate_required([:body, :author_id])
  end
end

