defmodule VisionsUnite.NewNotifications.NewNotification do
  use Ecto.Schema
  import Ecto.Changeset

  alias VisionsUnite.Expressions.Expression
  alias VisionsUnite.Accounts.User

  schema "new_notifications" do
    belongs_to :expression, Expression
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(new_notification, attrs) do
    new_notification
    |> cast(attrs, [:expression_id, :user_id])
    |> validate_required([:expression_id, :user_id])
    |> unique_constraint(:unique_notification, name: :unique_notification)
  end
end
