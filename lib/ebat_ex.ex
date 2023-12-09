defmodule Bot42 do
  @moduledoc """
  Bot42 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @spec cors_origin :: keyword()
  def cors_origin, do: Application.fetch_env!(:bot42, :cors)[:origin]
end
