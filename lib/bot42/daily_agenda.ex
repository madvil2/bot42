defmodule Bot42.DailyAgenda do
  alias Bot42.Telegram
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
    # today = ~D[2023-09-27]

    Enum.filter(events, fn event -> DateTime.to_date(event.dtstart) == today end)
  end

  @spec next_three_events([map()] | []) :: [map()] | []
  defp next_three_events(events) do
    today = Date.utc_today()

    events
    |> Enum.filter(fn event ->
      event.dtstart
      |> DateTime.to_date()
      |> Date.after?(today)
    end)
    |> Enum.sort_by(& &1.dtstart, DateTime)
    |> Enum.take(3)
  end

  @spec format_events([%ICalendar.Event{}] | []) :: String.t()
  defp format_events(events) do
    case events do
      [] ->
        next_events =
          events_from_calendar()
          |> case do
            {:ok, events} -> next_three_events(events)
            _ -> []
          end

        events_text = if Enum.empty?(next_events), do: "", else: format_next_events(next_events)

        "📆 *Today's Events*\n\n" <>
          "Unfortunately, there are no events scheduled for today 😔\n\n" <>
          events_text

      events ->
        "📆 *Today's Events*\n\n" <>
          Enum.map_join(events, "\n\n", fn event ->
            start_time = Calendar.strftime(event.dtstart, "%H:%M")
            end_time = Calendar.strftime(event.dtend, "%H:%M")
            date = Calendar.strftime(event.dtstart, "%Y-%m-%d")

            "📌 *#{event.summary}*\n\n" <>
              "🗓️ *Date:* #{date}\n" <>
              "🕒 *Time:* #{start_time} - #{end_time}\n" <>
              if(event.location != nil, do: "📍 *Location:* #{event.location}\n", else: "") <>
              if event.description != nil,
                do: "ℹ️ *Description:* #{String.slice(event.description, 0, 150)}...\n",
                else: ""
          end)
    end
  end

  @spec format_next_events([%ICalendar.Event{}] | []) :: String.t()
  defp format_next_events(events) do
    if Enum.empty?(events) do
      "📆 *Today's Events*\n\n" <>
        "Unfortunately, there are no events scheduled for today 😔\n\n"
    else
      "🔜 *However, here are the next 3 events:*\n\n" <>
        Enum.map_join(events, "\n\n", fn event ->
          start_time = Calendar.strftime(event.dtstart, "%H:%M")
          end_time = Calendar.strftime(event.dtend, "%H:%M")
          date = Calendar.strftime(event.dtstart, "%Y-%m-%d")

          "📌 *#{event.summary}*\n\n" <>
            "🗓️ *Date:* #{date}\n" <>
            "🕒 *Time:* #{start_time} - #{end_time}\n" <>
            if(event.location != nil, do: "📍 *Location:* #{event.location}\n", else: "") <>
            if event.description != nil,
              do: "ℹ️ *Description:* #{String.slice(event.description, 0, 150)}...\n",
              else: ""
        end)
    end
  end

  def send_daily_events do
    case formated_today_events() do
      {:ok, events} ->
        Telegram.send_message("585620866", format_events_for_chat(events),
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true
        )

      _ ->
        :error
    end
  end

  @spec format_events_for_chat([%ICalendar.Event{}] | []) :: String.t()
  defp format_events_for_chat(events) do
    case events do
      [] ->
        next_events =
          events_from_calendar()
          |> case do
            {:ok, events} -> next_three_events(events)
            _ -> []
          end

        events_text = if Enum.empty?(next_events), do: "", else: format_next_events(next_events)

        "📆 *Today's Events*\n\n" <>
          "Unfortunately, there are no events scheduled for today 😔\n\n" <>
          events_text

      events ->
        "📆 *Today's Events*\n\n" <>
          Enum.map_join(events, "\n\n", fn event ->
            start_time = Calendar.strftime(event.dtstart, "%H:%M")
            end_time = Calendar.strftime(event.dtend, "%H:%M")
            date = Calendar.strftime(event.dtstart, "%Y-%m-%d")

            "📌 *#{event.summary}*\n\n" <>
              "🗓️ *Date:* #{date}\n" <>
              "🕒 *Time:* #{start_time} - #{end_time}\n" <>
              if(event.location != nil, do: "📍 *Location:* #{event.location}\n", else: "") <>
              if event.description != nil,
                do: "ℹ️ *Description:* #{String.slice(event.description, 0, 150)}...\n",
                else: ""
          end)
    end
  end
end
