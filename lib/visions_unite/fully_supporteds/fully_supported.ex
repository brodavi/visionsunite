defmodule VisionsUnite.FullySupporteds.FullySupported do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Expressions.Expression

  schema "fully_supporteds" do
    belongs_to :expression, Expression
    belongs_to :group, Expression

    timestamps()
  end

  @doc false
  def changeset(expression_linkage, attrs) do
    expression_linkage
    |> cast(attrs, [:expression_id, :group_id])
    |> validate_required([:expression_id])
    |> unique_constraint(:unique_fully_supported, name: :unique_fully_supported)
  end
end

