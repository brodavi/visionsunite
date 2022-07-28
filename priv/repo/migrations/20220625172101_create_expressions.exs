defmodule VisionsUnite.Repo.Migrations.CreateExpressions do
  use Ecto.Migration

  def change do
    create table(:expressions) do
      add :title, :string
      add :body, :text
      add :fully_supported, :naive_datetime
      add :temperature, :float
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Expressions seeking support
    create table(:seeking_supports) do
      add :expression_id, references(:expressions, on_delete: :delete_all), null: false
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

      timestamps()
    end

    create index(:expressions, [:author_id])
    create index(:expression_linkages, [:expression_id, :link_id])
    create index(:seeking_supports, [:user_id])
    create unique_index(:seeking_supports, [:user_id,  :expression_id], name: :unique_support_seek)
  end
end

