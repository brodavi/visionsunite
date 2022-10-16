defmodule VisionsUnite.Expressions.Expression do
  use Ecto.Schema
  import Ecto.Changeset
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.ExpressionLinkages.ExpressionLinkage
  alias VisionsUnite.FullySupporteds.FullySupported

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
end

