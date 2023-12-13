defmodule YourApp.Repo.Migrations.AddIsAdminToUserRequests do
  use Ecto.Migration

  def change do
    alter table(:user_requests) do
      add :is_admin, :boolean, default: false
    end
  end
end
