defmodule Bot42.ResetRequestsWorker do
  use Oban.Worker, queue: :daily_reset, max_attempts: 1

  @impl true
  def perform(_job) do
    Bot42.UserRequests.reset_daily_request_counts()
  end
end
