defmodule Bot42.Repo.Migrations.AddUserIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_id, :integer
      modify :email, :string, null: true
    end
  end
end
