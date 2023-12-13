defmodule Bot42.DailyAgendaScheduler do
  use Cronex.Scheduler

  @daily_at_9am "40 12 * * *"

  def start_link do
    Cronex.Scheduler.start_link(name: __MODULE__)
  end

  def init do
    [
      {Bot42.DailyAgendaScheduler, :send_daily_events, [], @daily_at_9am}
    ]
  end

  def send_daily_events do
    Bot42.DailyAgenda.send_daily_events()
  end
end
