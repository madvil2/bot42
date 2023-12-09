defmodule Bot42.Repo.Migrations.AddUsersTududutuMessage do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tududutu_message, :string
    end
  end
end
