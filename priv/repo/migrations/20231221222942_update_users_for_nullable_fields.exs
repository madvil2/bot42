defmodule Bot42.Repo.Migrations.UpdateUsersForNullableFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :email, :string, null: true
      modify :hashed_password, :string, null: true
    end
  end
end
