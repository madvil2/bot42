defmodule Bot42.DailyAgenda do
  @spec daily_agenda_url :: String.t()
  defp daily_agenda_url do
    :bot42
    |> Application.fetch_env!(:daily_agenda)
    |> Keyword.fetch!(:url)
  end

  @spec formated_today_events :: {:ok, [map()] | []} | {:error, term()}
  def formated_today_events do
    case events_from_calendar() do
      {:ok, events} ->
        formated_today_events =
          events
          |> filter_today_events()
          |> format_events()

        {:ok, formated_today_events}

      {:error, _} = error ->
        error
    end
  end

  @spec events_from_calendar :: {:ok, [map()] | []} | {:error, :external_api_error | term()}
  defp events_from_calendar do
    case HTTPoison.get(daily_agenda_url()) do
      {:ok, %{status_code: 200, body: body}} -> parse_ical_data(body)
      _ -> {:error, :external_api_error}
    end
  end

  @spec parse_ical_data(String.t()) :: {:ok, [map()] | []} | {:error, :invalid_data}
  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      events when is_list(events) -> {:ok, events}
      _ -> {:error, :invalid_data}
    end
  end

  @spec filter_today_events([map()] | []) :: [map()] | []
  defp filter_today_events(events) do
    today = Date.utc_today()

    Enum.filter(events, fn event -> DateTime.to_date(event.dtstart)== today end)
  end

  @spec format_events([map()] | []) :: String.t()
  defp format_events(events) do
    case events do
      [] -> "Today's Agenda:\nNo events for today"

      events ->
        "Today's Agenda:\n" <>
          Enum.map_join(events, "\n", fn event ->
            start_time = Calendar.strftime(event.dtstart, "%H:%M")
            end_time = Calendar.strftime(event.dtend, "%H:%M")

            "#{event.summary}: from #{start_time} to #{end_time}"
          end)
    end
  end
end
