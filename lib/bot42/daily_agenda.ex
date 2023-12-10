defmodule Bot42.DailyAgenda do
  defp fetch_and_send_today_events(chat_id) do
    events = fetch_today_events_from_calendar()
    formatted_events = format_events(events)
    Telegram.send_message(chat_id, formatted_events)
  end

  defp fetch_today_events_from_calendar() do
    {:ok, response} = HTTPoison.get("https://calendar.google.com/calendar/ical/66d6b5eecc300121bc3d6af7c3a7e933f1625bef5450[…]28875bdccbdf8332@group.calendar.google.com/public/basic.ics")
    case response.status_code do
      200 -> parse_ical_data(response.body)
      _ -> []
    end
  end

  defp parse_ical_data(ical_data) do
    {:ok, calendars} = Icalendar.from_ical(ical_data)
    today = Date.utc_today()

    Enum.flat_map(calendars, fn calendar ->
      Enum.filter(calendar.events, fn event ->
        event.dtstart <= today and event.dtend >= today
      end)
    end)
  end

  def send_today_events(chat_id) do
    events = fetch_today_events_from_calendar()
    formatted_events = format_events(events)

    Telegram.send_message(chat_id, formatted_events)
  end

  defp format_events(events) do
    Enum.map(events, fn event ->
      start_time = format_time(event.dtstart)
      end_time = format_time(event.dtend)
      "#{event.summary}: from #{start_time} to #{end_time}"
    end)
    |> Enum.join("\n")
  end

  defp format_time(%DateTime{hour: hour, minute: minute}) do
    "#{pad_zero(hour)}:#{pad_zero(minute)}"
  end

  defp pad_zero(num) when num < 10, do: "0#{num}"
  defp pad_zero(num), do: "#{num}"


  @spec handle_user_commands(String.t() | nil, Telegex.Type.Chat.t()) :: :ok
  defp handle_user_commands("/help@school42bot", %{id: chat_id}) do
    text = "HELP: /help for help"

    {:ok, message} = Telegex.send_message(chat_id, text)

    Logger.info("Sent telegam tududu message: #{inspect(message)}")

    :ok
  end

  @spec handle_admin_command(String.t() | nil, Telegex.Type.Chat.t(), Accounts.User.t()) :: :ok
  defp handle_admin_command("/help@school42bot", %{id: chat_id}, user) do
    text = "HELP: /help for help"

    {:ok, message} = Telegex.send_message(chat_id, text)

    Logger.info("Sent telegam tududu message: #{inspect(message)}")

    :ok
  end
end
