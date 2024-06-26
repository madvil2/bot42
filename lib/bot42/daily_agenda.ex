defmodule Bot42.DailyAgenda do
  @placeholder_bold "BOLDPLACEHOLDER"
  alias Bot42.Telegram

  @spec daily_agenda_urls() :: [String.t()]
  defp daily_agenda_urls do
    [
      Application.fetch_env!(:bot42, :calendar_urls)[:intra_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:fablab_url],
      Application.fetch_env!(:bot42, :calendar_urls)[:mycustom_url]
    ]
  end

  @spec formated_today_events() :: {:ok, String.t()} | {:error, term()}
  def formated_today_events do
    case events_from_calendar() do
      {:ok, events} ->
        formatted_today_events =
          events
          |> filter_today_events()
          |> format_events(Date.utc_today())

        {:ok, formatted_today_events}

      {:error, _} = error ->
        error
    end
  end

  @spec formated_date_events(Date.t()) :: {:ok, String.t()} | {:error, term()}
  def formated_date_events(date) do
    case events_from_calendar() do
      {:ok, events} ->
        formatted_date_events =
          events
          |> filter_events_by_date(date)
          |> format_events(date)

        {:ok, formatted_date_events}

      {:error, _} = error ->
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

        {:ok, sorted_events}

      _error ->
        {:error, :external_api_error}
    end
  end

  @spec parse_ical_data(String.t()) :: {:ok, [map()] | []} | {:error, :invalid_data}
  defp parse_ical_data(ical_data) do
    case ICalendar.from_ics(ical_data) do
      events when is_list(events) ->
        expanded_events = Enum.flat_map(events, &expand_recurring_event(&1))
        {:ok, expanded_events}

      _ ->
        {:error, :invalid_data}
    end
  end

  @spec expand_recurring_event(%ICalendar.Event{}) :: [%ICalendar.Event{}]
  defp expand_recurring_event(event) do
    case event.rrule do
      nil ->
        [event]

      _rrule ->
        end_date = DateTime.utc_now() |> DateTime.add(365 * 24 * 60 * 60, :second)
        event |> ICalendar.Recurrence.get_recurrences(end_date) |> Enum.to_list()
    end
  end

  @spec filter_today_events([map()] | []) :: [map()] | []
  defp filter_today_events(events) do
    today = Date.utc_today()
    # today = ~D[2024-05-30]
    events
    |> filter_events_by_date(today)
    |> Enum.uniq_by(&{&1.summary, &1.dtstart, &1.dtend})
  end

  @spec filter_events_by_date([map()] | [], Date.t()) :: [map()] | []
  defp filter_events_by_date(events, date) do
    events
    |> Enum.filter(fn event ->
      event_date = DateTime.to_date(event.dtstart)
      event_date == date
    end)
    |> Enum.uniq_by(&{&1.summary, &1.dtstart, &1.dtend})
  end

  defp convert_to_timezone(datetime, timezone) do
    Timex.Timezone.convert(datetime, timezone)
  end

  @spec format_events([%ICalendar.Event{}] | [], Date.t()) :: String.t()
  defp format_events(events, date) do
    date_header = Calendar.strftime(date, "%d.%m.%Y")
    timezone = "Europe/Berlin"

    case events do
      [] ->
        "📆 #{@placeholder_bold}#{date_header} Events#{@placeholder_bold}\n\n" <>
          "Unfortunately, there are no events scheduled for this day 😔\n\n"

      events ->
        "📆 #{@placeholder_bold}#{date_header} Events#{@placeholder_bold}\n\n" <>
          Enum.map_join(events, "\n\n", fn event ->
            start_time =
              event.dtstart |> convert_to_timezone(timezone) |> Calendar.strftime("%H:%M")

            end_time = event.dtend |> convert_to_timezone(timezone) |> Calendar.strftime("%H:%M")

            "📌 #{@placeholder_bold}#{event.summary}#{@placeholder_bold}\n\n" <>
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
        # -1_002_067_092_609
        Telegram.send_message(-1_002_067_092_609, full_text,
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true
        )

      _ ->
        :error
    end
  end
end
