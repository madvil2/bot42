defmodule Bot42.TgHookHandler do
  use Telegex.Hook.GenHandler

  alias Bot42.ChatGpt
  alias Bot42.Telegram
  alias Bot42.DailyAgenda
  alias Bot42.UserRequests

  @spec tg_admin_chat_id :: integer()
  defp tg_admin_chat_id do
    :bot42
    |> Application.fetch_env!(:telegram)
    |> Keyword.fetch!(:admin_chat_id)
  end

  @impl true
  def on_boot do
    env_config = Application.fetch_env!(:bot42, __MODULE__)

    {:ok, true} = Telegex.delete_webhook()
    {:ok, true} = Telegex.set_webhook(env_config[:webhook_url])

    %Telegex.Hook.Config{server_port: env_config[:server_port]}
  end

  @impl true
  def on_failure(update, error) do
    error_message = "Error: #{inspect(error)} processing update: #{inspect(update)}"

    Logger.error(error_message)

    Telegram.send_message(tg_admin_chat_id(), error_message)
  end

  @impl true
  def on_update(%{message: message}) do
    Logger.info("Got telegam update with message: #{inspect(message)}")

    handle_update(message)
  end

  @spec handle_update(Telegex.Type.Message.t()) :: :ok
  defp handle_update(%{new_chat_members: members, chat: chat})
       when is_list(members) do
    Enum.each(members, fn member ->
      welcome_message = "Welcome @#{member.username}"

      Telegram.send_message(chat.id, welcome_message)
    end)
  end

  @spec handle_update(Telegex.Type.Message.t()) :: :ok
  defp handle_update(%{text: "/gpt" <> text, chat: chat, message_id: message_id}) do
    user_id = chat.id

    case Bot42.UserRequests.check_and_update_requests(user_id) do
      {:ok, remaining_requests} ->
        gpt_query = text |> String.trim_leading("/gpt ") |> String.trim()

        case ChatGpt.get_answer(gpt_query) do
          {:ok, answer} ->
            request_word = if remaining_requests == 1, do: "request", else: "requests"

            answer_message =
              answer <> "\n\nYou have *#{remaining_requests}* #{request_word} left today."

            :ok =
              Telegram.send_message(user_id, answer_message,
                reply_to_message_id: message_id,
                parse_mode: "MarkdownV2"
              )

          {:error, _} ->
            :error
        end

      {:limit_reached, _remaining_requests} ->
        :ok =
          Telegram.send_message(user_id, "You have reached your request limit for today.",
            reply_to_message_id: message_id
          )
    end
  end

  defp handle_update(%{text: "/today" <> _text, chat: chat, message_id: message_id}) do
    with {:ok, events_message} <- DailyAgenda.formated_today_events() do
      :ok =
        Telegram.send_message(chat.id, events_message,
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true,
          reply_to_message_id: message_id
        )
    end

    :ok
  end

  defp handle_update(%{text: "/help" <> _text, chat: chat, message_id: message_id}) do
    help_message =
      "Welcome to the Bot Help Menu!\nHere are the commands you can use:\n\n/today - Get the list of events from the 42 Berlin school calendar for today. Stay updated with the latest happenings!\n\n/gpt <text> - Ask any question to the ChatGPT. Just type your question after the command and get insights in no time.\n\nIf you have any questions or suggestions, feel free to reach out to me directly at @madvil2. I'm here to assist you!"

    Telegram.send_message(chat.id, help_message,
      parse_mode: "MarkdownV2",
      reply_to_message_id: message_id
    )
  end

  defp handle_update(update) do
    IO.inspect(update, label: "Unknown update")
  end
end
