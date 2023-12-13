defmodule Bot42.DailyAgendaScheduler do
  use Cronex.Scheduler

  # @daily_at_9am "0 9 * * *"
  @daily_at_12_10 "10 12 * * *"

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
