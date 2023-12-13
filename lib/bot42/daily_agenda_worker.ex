defmodule Bot42.DailyAgendaWorker do
  use Oban.Worker

  @impl true
  def perform(%Oban.Job{}) do
    Bot42.DailyAgenda.send_daily_events()
  end
end
