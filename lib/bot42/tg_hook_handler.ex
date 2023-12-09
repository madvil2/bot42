defmodule Bot42.TgHookHandler do
  use Telegex.Hook.GenHandler

  alias Bot42.Accounts

  @impl true
  def on_boot do
    env_config = Application.fetch_env!(:bot42, __MODULE__)

    {:ok, true} = Telegex.delete_webhook()
    {:ok, true} = Telegex.set_webhook(env_config[:webhook_url])

    %Telegex.Hook.Config{server_port: env_config[:server_port]}
  end

  def on_update(%{message: %{text: "/test", chat: chat}}) do
    Telegex.Client.send_message(chat.id, "test passed")
  end

  def handle_message(%{"text" => text, "chat" => %{"id" => chat_id}}) do
    if String.starts_with?(text, "/gpt") do
      query = String.trim_leading(text, "/gpt ")
      send_chat_gpt_request(query, chat_id)
    else
      :ignore
    end
  end

  defp send_chat_gpt_request(query, chat_id) do
    api_key = "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"
    url = "https://api.openai.com/v1/engines/text-davinci-003/completions"

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      prompt: query,
      max_tokens: 150,
      temperature: 0.7
    }
    |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        response = Jason.decode!(response_body)
        text_response = response["choices"] |> List.first() |> Map.get("text")
        send_response_to_user(text_response, chat_id)
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp send_response_to_user(text_response, chat_id) do
    Telegex.Bot.send_message(chat_id, text_response)
  end

  def on_update(%{message: %{text: "/today", from: from, chat: chat} = message}) do
    send_today_events(chat.id)
  end

  @impl true
  def on_update(%{message: %{new_chat_members: members} = message}) do
    Enum.each(members, fn member ->
      welcome_message = "Welcome #{member.username}"
      Telegex.send_message(message.chat.id, welcome_message)
    end)
  end

  def on_update(%{message: %{from: from, chat: chat, text: text} = message}) do
    Logger.info("Got telegam update with message: #{inspect(message)}")

    case Accounts.get_user_by_tg_username(from.username) do
      nil ->
        :ok = handle_user_commands(text, chat)

        :ok

      user ->
        :ok = handle_admin_command(text, chat, user)

        :ok
    end
  end

  def fetch_and_send_today_events(chat_id) do
    events = fetch_today_events_from_calendar()
    formatted_events = format_events(events)
    Telegex.send_message(chat_id, formatted_events)
  end

  def fetch_today_events_from_calendar() do
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
    Telegex.send_message(chat_id, formatted_events)
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
  defp handle_user_commands("/help", %{id: chat_id}) do
    text = "HELP: /help for help"

    {:ok, message} = Telegex.send_message(chat_id, text)

    Logger.info("Sent telegam tududu message: #{inspect(message)}")

    :ok
  end

  @spec handle_admin_command(String.t() | nil, Telegex.Type.Chat.t(), Accounts.User.t()) :: :ok
  defp handle_admin_command("/help", %{id: chat_id}, user) do
    text = "HELP: /help for help"

    {:ok, message} = Telegex.send_message(chat_id, text)

    Logger.info("Sent telegam tududu message: #{inspect(message)}")

    :ok
  end
end
