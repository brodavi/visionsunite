defmodule VisionsUnite.Supports.Support do
  use Ecto.Schema
  import Ecto.Changeset
  alias VisionsUnite.Accounts.User
  alias VisionsUnite.Expressions.Expression

  schema "supports" do
    field :support, :float
    field :note, :string

    belongs_to :user, User
    belongs_to :expression, Expression
    belongs_to :for_group, Expression

    timestamps()
  end

  @doc false
  def changeset(supporting, attrs) do
    supporting
    |> cast(attrs, [:user_id, :expression_id, :for_group_id, :support, :note])
    |> validate_required([:user_id, :expression_id, :support])
  end
end

