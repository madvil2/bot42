defmodule Bot42.Repo.Migrations.ModifyUsersTududutuMessage do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :tududutu_message, :text, from: :string
    end
  end
end
