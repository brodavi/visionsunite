defmodule VisionsUnite.Repo.Migrations.FullySupportedExpression do
  use Ecto.Migration

  def change do
    alter table(:expressions) do
      add :fully_supported, :naive_datetime
    end
  end
end

