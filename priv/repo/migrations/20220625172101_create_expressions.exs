defmodule VisionsUnite.Repo.Migrations.CreateExpressions do
  use Ecto.Migration

  def change do
    create table(:expressions) do
      add :title, :string
      add :body, :text
      add :temperature, :float
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Expressions seeking support
    create table(:seeking_supports) do
      add :expression_id, references(:expressions, on_delete: :delete_all), null: false
      add :for_group_id, references(:expressions, on_delete: :delete_all), null: true # NOTE can be null (root expressions)
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Expressions' linkage
    create table(:expression_linkages) do
      add :expression_id, references(:expressions, on_delete: :delete_all), null: false
      add :link_id, references(:expressions, on_delete: :delete_all), null: false

      timestamps()
    end

    # Users' subscription to expressions
    create table(:expression_subscriptions) do
      add :expression_id, references(:expressions, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :subscribe, :boolean

      timestamps()
    end

    # Create some indices
    create index(:expressions, [:author_id])

    create index(:expression_linkages, [:expression_id, :link_id])
    create unique_index(:expression_linkages, [:expression_id, :link_id], name: :unique_link)

    create index(:expression_subscriptions, [:expression_id, :user_id, :subscribe])
    create unique_index(:expression_subscriptions, [:expression_id, :user_id, :subscribe], name: :unique_subscription)

    create index(:seeking_supports, [:user_id])
    create unique_index(:seeking_supports, [:expression_id, :user_id, :for_group_id], name: :unique_support_seek)
  end
end

