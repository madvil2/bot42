defmodule Bot42Web.PageController do
  use Bot42Web, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/users/settings")
  end
end
