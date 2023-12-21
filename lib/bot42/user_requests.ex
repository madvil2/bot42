defmodule Bot42.UserRequests do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Bot42.Repo

  schema "users" do
    field :email, :string
    field :tg_username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :request_count, :integer, default: 0
    field :last_request_date, :date
    field :is_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def is_user_admin(tg_username) do
    user = Repo.get_by(Bot42.UserRequests, tg_username: tg_username)

    case user do
      nil ->
        false

      %Bot42.UserRequests{is_admin: is_admin_status} ->
        is_admin_status
    end
  end

  def check_and_update_requests(tg_username) do
    user =
      Repo.get_by(Bot42.UserRequests, tg_username: tg_username)

    max_requests = 10

    case user do
      nil ->
        new_user = %Bot42.UserRequests{
          tg_username: tg_username,
          request_count: 1,
          last_request_date: Date.utc_today(),
          is_admin: false
        }

        Repo.insert(new_user)
        {:ok, max_requests - 1}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: true} ->
        {:ok, :unlimited}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: false} ->
        updated_user =
          if date != Date.utc_today() do
            %{request_count: 1, last_request_date: Date.utc_today()}
          else
            if count >= max_requests do
              %{request_count: count}
            else
              %{request_count: count + 1}
            end
          end

        user
        |> change(updated_user)
        |> Repo.update()

        if count >= max_requests do
          {:limit_reached, 0}
        else
          {:ok, max_requests - count - 1}
        end
    end
  end

  def add_user_admin(tg_username) do
    user = Repo.get_by(Bot42.UserRequests, tg_username: tg_username)

    case user do
      nil ->
        {:error, "User not found"}

      %Bot42.UserRequests{} ->
        user
        |> change(%{is_admin: true})
        |> Repo.update()

        {:ok, "User is now an admin"}
    end
  end

  def remove_user_admin(tg_username) do
    user = Repo.get_by(Bot42.UserRequests, tg_username: tg_username)

    case user do
      nil ->
        {:error, "User not found"}

      %Bot42.UserRequests{} ->
        user
        |> change(%{is_admin: false})
        |> Repo.update()

        {:ok, "User is now removed from admins"}
    end
  end

  def reset_daily_request_counts do
    Repo.update_all(Bot42.UserRequests, set: [request_count: 0])
    IO.puts("All user request counts have been reset.")
  end
end
