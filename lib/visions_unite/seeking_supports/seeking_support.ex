defmodule VisionsUnite.SeekingSupports.SeekingSupport do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Accounts.User
  alias VisionsUnite.Expressions.Expression

  schema "seeking_supports" do
    belongs_to :user, User
    belongs_to :expression, Expression
    belongs_to :for_group, Expression

    timestamps()
  end

  @doc false
  def changeset(seeking_support, attrs) do
    seeking_support
    |> cast(attrs, [:user_id, :expression_id, :for_group_id])
    |> validate_required([:user_id, :expression_id])
    |> unique_constraint(:unique_support_seek, name: :unique_support_seek)
  end
end

