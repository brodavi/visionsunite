defmodule VisionsUnite.Repo.Migrations.NewNotifications do
  use Ecto.Migration

  def change do
    create table(:new_notifications) do
      add :expression_id, references(:expressions, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:new_notifications, [:expression_id])
    create index(:new_notifications, [:user_id])

    create unique_index(:new_notifications, [:user_id, :expression_id], name: :unique_notification)
  end
end
