defmodule Bot42.UserRequests do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bot42.Repo

  schema "user_requests" do
    field :user_id, :integer
    field :request_count, :integer, default: 0
    field :last_request_date, :date
    field :is_admin, :boolean, default: false
    timestamps()
  end

  def is_user_admin(user_id) do
    user_request = Repo.get_by(Bot42.UserRequests, user_id: user_id)

    case user_request do
      nil ->
        false

      %Bot42.UserRequests{is_admin: is_admin_status} ->
        is_admin_status
    end
  end

  def check_and_update_requests(user_id) do
    user_request =
      Repo.get_by(Bot42.UserRequests, user_id: user_id)

    max_requests = 10

    case user_request do
      nil ->
        new_user_request = %Bot42.UserRequests{
          user_id: user_id,
          request_count: 1,
          last_request_date: Date.utc_today(),
          is_admin: false
        }

        Repo.insert(new_user_request)

        {:ok, max_requests - 1}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: true} ->
        {:ok, :unlimited}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: false} ->
        if date != Date.utc_today() do
          user_request
          |> change(%{request_count: 1, last_request_date: Date.utc_today()})
          |> Repo.update()

          {:ok, max_requests - 1}
        else
          if count >= max_requests do
            {:limit_reached, 0}
          else
            user_request
            |> change(%{request_count: count + 1})
            |> Repo.update()

            {:ok, max_requests - count - 1}
          end
        end
    end
  end

  def add_user_admin(user_id) do
    user_request = Repo.get_by(Bot42.UserRequests, user_id: user_id)

    case user_request do
      nil ->
        {:error, "User not found"}

      %Bot42.UserRequests{} ->
        user_request
        |> change(%{is_admin: true})
        |> Repo.update()

        {:ok, "User is now an admin"}
    end
  end

  def remove_user_admin(user_id) do
    user_request = Repo.get_by(Bot42.UserRequests, user_id: user_id)

    case user_request do
      nil ->
        {:error, "User not found"}

      %Bot42.UserRequests{} ->
        user_request
        |> change(%{is_admin: false})
        |> Repo.update()

        {:ok, "User is now removed from admins"}
    end
  end
end
