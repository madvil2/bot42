defmodule Bot42.UserRequests do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Bot42.Repo

  schema "user_requests" do
    field :user_id, :integer
    field :username, :string
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

  def check_and_update_requests(user_id, username) do
    user_request =
      Repo.get_by(Bot42.UserRequests, user_id: user_id)

    max_requests = 10

    case user_request do
      nil ->
        new_user_request = %Bot42.UserRequests{
          user_id: user_id,
          username: username,
          request_count: 1,
          last_request_date: Date.utc_today(),
          is_admin: false
        }

        Repo.insert(new_user_request)

        {:ok, max_requests - 1}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: true} ->
        {:ok, :unlimited}

      %Bot42.UserRequests{request_count: count, last_request_date: date, is_admin: false} ->
        updated_user_request =
          if date != Date.utc_today() do
            %{request_count: 1, last_request_date: Date.utc_today(), username: username}
          else
            if count >= max_requests do
              %{request_count: count}
            else
              %{request_count: count + 1, username: username}
            end
          end

        user_request
        |> change(updated_user_request)
        |> Repo.update()

        if count >= max_requests do
          {:limit_reached, 0}
        else
          {:ok, max_requests - count - 1}
        end
    end
  end

  @spec get_user_id_by_username(username :: String.t()) :: {:ok, integer()} | {:error, any()}
  def get_user_id_by_username(username) do
    # Логирование входящего значения username
    IO.inspect(username, label: "Searched username")

    query =
      from(u in Bot42.UserRequests,
        where: u.username == ^username,
        select: u.user_id
      )

    # Логирование сформированного запроса
    IO.inspect(query, label: "Database query")

    case Repo.one(query) do
      nil ->
        # Логирование, если пользователь не найден
        IO.inspect(username, label: "User not found for username")
        {:error, "User not found"}

      user_id ->
        # Логирование найденного user_id
        IO.inspect(user_id, label: "Found user_id")
        {:ok, user_id}
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
