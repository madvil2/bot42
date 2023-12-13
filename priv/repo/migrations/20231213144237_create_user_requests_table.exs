defmodule YourApp.Repo.Migrations.CreateUserRequestsTable do
  use Ecto.Migration

  def change do
    create table(:user_requests) do
      add :user_id, :bigint, primary_key: true
      add :request_count, :integer, default: 0
      add :last_request_date, :date

      timestamps()
    end
  end
end
