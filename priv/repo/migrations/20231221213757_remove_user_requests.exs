defmodule Bot42.Repo.Migrations.RemoveUserRequests do
  use Ecto.Migration

  def change do
    drop table(:user_requests)
  end
end
