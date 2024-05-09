defmodule Bot42.DailyAgenda do
  @placeholder_bold "BOLDPLACEHOLDER"
  alias Bot42.Telegram
  @spec daily_agenda_urls :: [String.t()]
  defp daily_agenda_urls do
    [
      Application.fetch_env!(:bot42, :calendar_urls)[:intra_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:fablab_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:mycustom_url]
    ]

    # |> IO.inspect(label: "Fetched URLs")
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

      # |> IO.inspect(label: "Formatted Events")

      {:error, _} = error ->
        error
        # |> IO.inspect(label: "Error in Events Fetching")
    end
  end

  @spec events_from_calendar :: {:ok, [map()] | []} | {:error, :external_api_error | term()}
  defp events_from_calendar do
    urls = daily_agenda_urls()

    urls
    |> Enum.map(fn url ->
      case HTTPoison.get(url) do
        {:ok, %{status_code: 200, body: body}} ->
          parse_ical_data(body)

        # |> IO.inspect(label: "Calendar Data from URL: #{url}")

        {:error, reason} ->
          {:error, {:external_api_error, reason}}
          # |> IO.inspect(label: "Failed to Fetch URL: #{url}")
      end
    end)
    |> merge_calendar_events()

    # |> IO.inspect(label: "Merged Events")
  end

  @spec merge_calendar_events([{:ok, [map()]} | {:error, term()}]) ::
          {:ok, [map()] | []} | {:error, :external_api_error}
  defp merge_calendar_events(responses) do
    case Enum.find(responses, fn response -> match?({:error, _}, response) end) do
      nil ->
        events = Enum.flat_map(responses, fn {:ok, events} -> events end)

        # Сортировка событий по времени начала
        sorted_events = Enum.sort_by(events, fn event -> event.dtstart end)

        {:ok, sorted_events}

      _error ->
        {:error, :external_api_error}
        # |> IO.inspect(label: "Error during Event Merging")
    end
  end

  @spec parse_ical_data(String.t()) :: {:ok, [map()] | []} | {:error, :invalid_data}
  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      events when is_list(events) ->
        {:ok, events}

      _ ->
        {:error, :invalid_data}
        # |> IO.inspect(label: "Failed to Parse iCal Data")
    end
  end

  @spec filter_today_events([map()] | []) :: [map()] | []
  defp filter_today_events(events) do
    today = Date.utc_today()
    # For specific debugging with a set date, uncomment the next line:
    # today = ~D[2024-05-09]

    # IO.inspect(today, label: "Current Date for Filtering")
    # IO.inspect(events, label: "Events Before Filtering")

    filtered_events =
      Enum.filter(events, fn event ->
        # Assuming `event.dtstart` is a DateTime struct:
        event_date = DateTime.to_date(event.dtstart)
        event_date == today
      end)

    # IO.inspect(filtered_events, label: "Events After Filtering")

    filtered_events
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

        "📆 #{@placeholder_bold}Today's Events#{@placeholder_bold}\n\n" <>
          "Unfortunately, there are no events scheduled for today 😔\n\n" <>
          events_text

      events ->
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
    end
  end

  @spec format_next_events([%ICalendar.Event{}] | []) :: String.t()
  defp format_next_events(events) do
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
  end

  def send_daily_events do
    case formated_today_events() do
      {:ok, text} ->
        greet =
          "Guten Morgen, 42 coders! 🌅\nThe sun is up, and that means it's time to check out today's events.\n\n"

        full_text = greet <> text
        # -4_040_331_382
        Telegram.send_message(-1_002_067_092_609, full_text,
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true
        )

      _ ->
        :error
    end
  end
end
