defmodule Bot42.Repo do
  use Ecto.Repo,
    otp_app: :bot42,
    adapter: Ecto.Adapters.Postgres
end
