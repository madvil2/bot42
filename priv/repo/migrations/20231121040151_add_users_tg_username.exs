defmodule Bot42.Repo.Migrations.AddUsersTgUsername do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tg_username, :string
      add :social_status, :string
    end

    create unique_index(:users, [:tg_username])
  end
end
