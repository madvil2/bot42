defmodule Bot42.Repo.Migrations.UpdateIntegerFieldToBigInt do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :user_id, :bigint
    end
  end
end
