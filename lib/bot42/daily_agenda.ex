defmodule Bot42.DailyAgenda do
  require Logger
  @placeholder_bold "BOLDPLACEHOLDER"
  alias Bot42.Telegram

  @spec daily_agenda_urls :: [String.t()]
  defp daily_agenda_urls do
    [
      Application.fetch_env!(:bot42, :calendar_urls)[:intra_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:fablab_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:mycustom_url]
    ]
  end

  @spec formated_today_events :: {:ok, [map()] | []} | {:error, term()}
  def formated_today_events do
    Logger.info("Fetching today's events")

    case events_from_calendar() do
      {:ok, events} ->
        formatted_today_events =
          events
          |> filter_today_events()
          |> format_events()

        {:ok, formatted_today_events}

      {:error, _} = error ->
        Logger.error("Error fetching today's events: #{inspect(error)}")
        error
    end
  end

  @spec formated_date_events(Date.t()) :: {:ok, String.t()} | {:error, term()}
  def formated_date_events(date) do
    Logger.info("Fetching events for date: #{date}")

    case events_from_calendar() do
      {:ok, events} ->
        formatted_date_events =
          events
          |> filter_events_by_date(date)
          |> format_events()

        {:ok, formatted_date_events}

      {:error, _} = error ->
        Logger.error("Error fetching events for date #{date}: #{inspect(error)}")
        error
    end
  end

  @spec events_from_calendar() :: {:ok, [map()] | []} | {:error, :external_api_error | term()}
  defp events_from_calendar do
    urls = daily_agenda_urls()

    urls
    |> Enum.map(fn url ->
      case HTTPoison.get(url) do
        {:ok, %{status_code: 200, body: body}} ->
          parse_ical_data(body)

        {:error, reason} ->
          Logger.error("Error fetching calendar from URL #{url}: #{inspect(reason)}")
          {:error, {:external_api_error, reason}}
      end
    end)
    |> merge_calendar_events()
  end

  @spec merge_calendar_events([{:ok, [map()]} | {:error, term()}]) ::
          {:ok, [map()] | []} | {:error, :external_api_error}
  defp merge_calendar_events(responses) do
    case Enum.find(responses, fn response -> match?({:error, _}, response) end) do
      nil ->
        events = Enum.flat_map(responses, fn {:ok, events} -> events end)
        sorted_events = Enum.sort_by(events, fn event -> event.dtstart end)

        Logger.info("Merged and sorted events: #{inspect(sorted_events)}")
        {:ok, sorted_events}

      _error ->
        Logger.error("Error merging calendar events: #{inspect(responses)}")
        {:error, :external_api_error}
    end
  end

  @spec parse_ical_data(String.t()) :: {:ok, [map()] | []} | {:error, :invalid_data}
  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      {:ok, %ICalendar{events: events}} when is_list(events) ->
        expanded_events = Enum.flat_map(events, &expand_recurrences/1)
        Logger.info("Parsed and expanded events: #{inspect(expanded_events)}")
        {:ok, expanded_events}

      {:ok, _} ->
        Logger.error("Invalid iCal data: #{ical_data}")
        {:error, :invalid_data}

      _ ->
        Logger.error("Failed to parse iCal data: #{ical_data}")
        {:error, :invalid_data}
    end
  end

  defp expand_recurrences(event) do
    case event.rrule do
      nil ->
        [event]

      _ ->
        recurrences =
          ICalendar.Recurrence.get_recurrences(event, Timex.shift(DateTime.utc_now(), years: 1))
          |> Enum.to_list()

        Logger.info("Recurrences for event #{event.summary}: #{inspect(recurrences)}")
        recurrences
    end
  end

  @spec filter_today_events([map()] | []) :: [map()] | []
  defp filter_today_events(events) do
    today = Date.utc_today()
    filter_events_by_date(events, today)
  end

  @spec filter_events_by_date([map()] | [], Date.t()) :: [map()] | []
  defp filter_events_by_date(events, date) do
    filtered_events =
      Enum.filter(events, fn event ->
        event_date = DateTime.to_date(event.dtstart)
        event_date == date
      end)

    Logger.info("Filtered events for date #{date}: #{inspect(filtered_events)}")
    filtered_events
  end

  @spec next_three_events([map()] | []) :: [map()] | []
  defp next_three_events(events) do
    today = Date.utc_today()

    next_events =
      events
      |> Enum.filter(fn event ->
        event.dtstart
        |> DateTime.to_date()
        |> Date.after?(today)
      end)
      |> Enum.sort_by(& &1.dtstart, DateTime)
      |> Enum.take(3)

    Logger.info("Next three events: #{inspect(next_events)}")
    next_events
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

        formatted_text =
          "📆 #{@placeholder_bold}Today's Events#{@placeholder_bold}\n\n" <>
            "Unfortunately, there are no events scheduled for today 😔\n\n" <>
            events_text

        Logger.info("Formatted events text (no events): #{formatted_text}")
        formatted_text

      events ->
        formatted_text =
          "📆 #{@placeholder_bold}Today's Events#{@placeholder_bold}\n\n" <>
            Enum.map_join(events, "\n\n", fn event ->
              start_time = Calendar.strftime(event.dtstart, "%H:%M")
              end_time = Calendar.strftime(event.dtend, "%H:%M")
              date = Calendar.strftime(event.dtstart, "%Y-%m-%d")

              "📌 #{@placeholder_bold}#{event.summary}#{@placeholder_bold}\n\n" <>
                "🗓️ #{@placeholder_bold}Date:#{@placeholder_bold} #{date}\n" <>
                "🕒 #{@placeholder_bold}Time:#{@placeholder_bold} #{start_time} - #{end_time}\n" <>
                if(event.location != nil,
                  do: "📍 #{@placeholder_bold}Location:#{@placeholder_bold} #{event.location}\n",
                  else: ""
                )
            end)

        Logger.info("Formatted events text: #{formatted_text}")
        formatted_text
    end
  end

  @spec format_next_events([%ICalendar.Event{}] | []) :: String.t()
  defp format_next_events(events) do
    formatted_text =
      if Enum.empty?(events) do
        "📆 #{@placeholder_bold}Today's Events#{@placeholder_bold}\n\n" <>
          "Unfortunately, there are no events scheduled for today 😔\n\n"
      else
        "🔜 #{@placeholder_bold}However, here are the next 3 events:#{@placeholder_bold}\n\n" <>
          Enum.map_join(events, "\n\n", fn event ->
            start_time = Calendar.strftime(event.dtstart, "%H:%M")
            end_time = Calendar.strftime(event.dtend, "%H:%M")
            date = Calendar.strftime(event.dtstart, "%Y-%m-%d")

            "📌 #{@placeholder_bold}#{event.summary}#{@placeholder_bold}\n\n" <>
              "🗓️ #{@placeholder_bold}Date:#{@placeholder_bold} #{date}\n" <>
              "🕒 #{@placeholder_bold}Time:#{@placeholder_bold} #{start_time} - #{end_time}\n" <>
              if(event.location != nil,
                do: "📍 #{@placeholder_bold}Location:#{@placeholder_bold} #{event.location}\n",
                else: ""
              )
          end)
      end

    Logger.info("Formatted next events text: #{formatted_text}")
    formatted_text
  end

  def send_daily_events do
    case formated_today_events() do
      {:ok, text} ->
        greet =
          "Guten Morgen, 42 coders! 🌅\nThe sun is up, and that means it's time to check out today's events.\n\n"

        full_text = greet <> text
        Logger.info("Sending daily events: #{full_text}")

        Telegram.send_message(-1_002_067_092_609, full_text,
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true
        )

      {:error, reason} ->
        Logger.error("Failed to format today's events: #{inspect(reason)}")
        :error
    end
  end
end
