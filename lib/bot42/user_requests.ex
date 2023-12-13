defmodule Bot42.UserRequests do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bot42.Repo

  schema "user_requests" do
    field :user_id, :integer
    field :request_count, :integer, default: 0
    field :last_request_date, :date
    timestamps()
  end

  def check_and_update_requests(user_id) do
    user_request =
      Repo.get_by(Bot42.UserRequests, user_id: user_id)

    max_requests = 10

    case user_request do
      nil ->
        %Bot42.UserRequests{
          user_id: user_id,
          request_count: 1,
          last_request_date: Date.utc_today()
        }
        |> Repo.insert()

        {:ok, max_requests - 1}

      %Bot42.UserRequests{request_count: count, last_request_date: date} ->
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
end
