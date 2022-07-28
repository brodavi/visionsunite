defmodule VisionsUnite.Expressions.Expression do
  use Ecto.Schema
  import Ecto.Changeset
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.ExpressionLinkages.ExpressionLinkage

  schema "expressions" do
    field :title, :string
    field :body, :string
    field :temperature, :float
    field :fully_supported, :naive_datetime

    belongs_to :author, User
    has_many :expression_linkages, ExpressionLinkage
    has_many :links, through: [:expression_linkages, :link]

    timestamps()
  end

  @doc false
  def changeset(expression, attrs) do
    expression
    |> cast(attrs, [:title, :body, :temperature, :author_id, :fully_supported])
    |> validate_required([:title, :body, :author_id])
  end
end

