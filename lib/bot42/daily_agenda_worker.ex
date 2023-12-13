defmodule Bot42.DailyAgendaWorker do
  use Oban.Worker, queue: :daily_agenda

  @impl Oban.Worker
  def perform(_) do
    Bot42.DailyAgenda.send_daily_events()
    :ok
  end
end
