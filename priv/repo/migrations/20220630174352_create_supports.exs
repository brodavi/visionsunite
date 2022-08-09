defmodule VisionsUnite.Repo.Migrations.CreateSupports do
  use Ecto.Migration

  def change do
    create table(:supports) do
      add :support, :float
      add :note, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :expression_id, references(:expressions, on_delete: :delete_all)
      add :for_group_id, references(:expressions, on_delete: :delete_all)

      timestamps()
    end

    create index(:supports, [:user_id])
    create index(:supports, [:expression_id])
    create index(:supports, [:for_group_id])
  end
end

