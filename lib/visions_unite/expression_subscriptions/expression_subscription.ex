defmodule VisionsUnite.ExpressionSubscriptions.ExpressionSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.Accounts.User

  schema "expression_subscriptions" do
    field :subscribe, :boolean
    belongs_to :expression, Expression
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(expression_subscription, attrs) do
    expression_subscription
    |> cast(attrs, [:expression_id, :user_id, :subscribe])
    |> validate_required([:expression_id, :user_id, :subscribe])
    |> unique_constraint(:unique_subscription, name: :unique_subscription)
  end
end

