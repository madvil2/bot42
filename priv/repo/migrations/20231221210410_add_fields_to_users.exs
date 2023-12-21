defmodule Bot42.Repo.Migrations.AddFieldstoUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :request_count, :integer, default: 0
      add :last_request_date, :date
      add :is_admin, :boolean, default: false
    end
  end
end
