defmodule YourApp.Repo.Migrations.AddUsernameToUserRequests do
  use Ecto.Migration

  def change do
    alter table(:user_requests) do
      add :username, :string
    end
  end
end
