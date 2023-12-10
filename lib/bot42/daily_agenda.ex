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
    # today = Date.utc_today()
    today = ~D[2023-09-27]

    Enum.filter(events, fn event -> DateTime.to_date(event.dtstart)== today end)
  end

  @spec format_events([%ICalendar.Event{}] | []) :: String.t()
  defp format_events(events) do
    case events do
      [] ->
        "📅 *Today's Events*\n\n" <>
        "Unfortunately, there are no events scheduled for today 😔"

      events ->
        "📅 *Today's Events*\n\n" <>
        Enum.map_join(events, "\n\n", fn event ->
          start_time = Calendar.strftime(event.dtstart, "%H:%M")
          end_time = Calendar.strftime(event.dtend, "%H:%M")

          "📌 *#{event.summary}*\n\n" <>
          "🕒 Time: #{start_time} \\- #{end_time}\n" <>
          (if event.location != nil, do: "📍 Location: #{event.location}\n", else: "") <>
          (if event.description != nil, do: "ℹ️ Description: #{String.slice(event.description, 0, 200)}...\n", else: "")
        end)
    end
  end
end
