defmodule Bot42.DailyAgenda do
  @spec daily_agenda_url :: String.t()
  defp daily_agenda_url do
    :bot42
    |> Application.fetch_env!(:daily_agenda)
    |> Keyword.fetch!(:url)
  end

  @spec formated_today_events :: {:ok, [map()] | []} | {:error, term()}
  def formated_today_events do
    case today_events_from_calendar() do
      {:ok, events} ->
        IO.inspect(events, label: "События перед форматированием")
        {:ok, format_events(events)}

      {:error, _} = error ->
        error
    end
  end


  @spec today_events_from_calendar :: {:ok, [map()] | []} | {:error, :external_api_error | term()}
  defp today_events_from_calendar do
    case HTTPoison.get(daily_agenda_url()) do
      {:ok, %{status_code: 200, body: body}} ->
        IO.inspect(body, label: "Ответ от календаря")
        parse_ical_data(body)

      response ->
        IO.inspect(response, label: "Неудачный ответ от календаря")
        {:error, :external_api_error}
    end
  end

  @spec parse_ical_data(Strig.t()) :: {:ok, [map()] | []} | {:error, :invalid_data}
  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      {:ok, calendars} ->
        IO.inspect(ical_data, label: "ical_data")
        today = Date.utc_today()
        current_time = DateTime.utc_now()

        events =
          Enum.flat_map(calendars, fn calendar ->
            Enum.filter(calendar.events, fn event ->
              date_comparison = Date.compare(event.dtstart, today)
              (date_comparison in [:eq, :lt]) and event.dtend > current_time
            end)
          end)

        case events do
          [] -> {:ok, "No events"}
          _ -> {:ok, events}
        end

      _ ->
        {:error, :invalid_data}
    end
  end



  @spec format_events([map()] | []) :: String.t()
  defp format_events(events) do
    events
    |> Enum.map(fn event ->
      start_time = Calendar.strftime(event.dtstart, "%a, %B %d %Y")
      end_time = Calendar.strftime(event.dtend, "%a, %B %d %Y")

      "#{event.summary}: from #{start_time} to #{end_time}"
    end)
    |> Enum.join("\n")
  end
end
