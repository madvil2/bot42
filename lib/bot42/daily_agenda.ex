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
        parse_ical_data(body)

      response ->
        IO.inspect(response, label: "Неудачный ответ от календаря")
        {:error, :external_api_error}
    end
  end

  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      {:ok, calendars} ->
        filter_and_process_events(calendars)

      events when is_list(events) ->
        if Enum.all?(events, &is_struct(&1, ICalendar.Event)) do
          filter_and_process_events_direct(events)
        else
          {:error, :invalid_data}
        end

      _ ->
        {:error, :invalid_data}
    end
  end

  defp filter_and_process_events(calendars) do
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
  end

  defp filter_and_process_events_direct(events) do
    today = Date.utc_today()
    current_time = DateTime.utc_now()

    filtered_events =
      Enum.filter(events, fn event ->
        date_comparison = Date.compare(event.dtstart, today)
        (date_comparison in [:eq, :lt]) and event.dtend > current_time
      end)

    case filtered_events do
      [] -> {:ok, "No events"}
      _ -> {:ok, filtered_events}
    end
  end

  @spec format_events([map()] | []) :: String.t()
  defp format_events(events) do
    "Today's Agenda:\n" <>
      Enum.map_join(events, "\n", fn event ->
        start_time = Calendar.strftime(event.dtstart, "%H:%M")
        end_time = Calendar.strftime(event.dtend, "%H:%M")

        "#{event.summary}: from #{start_time} to #{end_time}"
      end)
  end
end
