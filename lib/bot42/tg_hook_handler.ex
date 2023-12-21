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

  @spec handle_update(Telegex.Type.Message.t()) :: :ok
  defp handle_update(%{text: "/admin " <> rest, chat: chat, from: from, message_id: message_id}) do
    admin_chat_id = tg_admin_chat_id()

    if UserRequests.is_user_admin(from.username) or admin_chat_id == chat.id do
      handle_admin_command(rest, chat, from, message_id)
    else
      Telegram.send_message(
        chat.id,
        "Only admins can use admin commands, or use in the admin chat.",
        reply_to_message_id: message_id,
        parse_mode: "MarkdownV2"
      )
    end
  end

  @spec handle_update(Telegex.Type.Message.t()) :: :ok
  defp handle_update(%{text: "/help" <> _text, chat: chat, message_id: message_id}) do
    help_message =
      "Welcome to the Bot Help Menu!\nHere are the commands you can use:\n\n/today - Get the list of events from the 42 Berlin school calendar for today. Stay updated with the latest happenings!\n\n@school42bot <text> - Ask any question to the ChatGPT. Just mention @school42bot followed by your question and get insights in no time. The mention will be replaced with 'ChatGPT' when processing your request. Remember, you have a limit of 10 requests per day, so use them wisely!\n\nIf you have any questions or suggestions, feel free to reach out to me directly at @madvil2. I'm here to assist you!"

    Telegram.send_message(chat.id, help_message,
      parse_mode: "MarkdownV2",
      reply_to_message_id: message_id
    )
  end

  @spec handle_update(Telegex.Type.Message.t()) :: :ok
  defp handle_update(%{
         text: text,
         chat: chat,
         from: from,
         message_id: message_id,
         reply_to_message: reply_to_message
       }) do
    bot_username = "@school42bot"
    IO.inspect(reply_to_message.from.username, label: "Reply to Message")

    is_mention_or_reply =
      (text != nil and String.contains?(text, bot_username)) or
        (reply_to_message != nil and reply_to_message.from.username == "school42bot")

    if is_mention_or_reply do
      gpt_query = String.replace(text, bot_username, "ChatGPT")

      case UserRequests.check_and_update_requests(from.id, from.username) do
        {:ok, remaining_requests} ->
          case ChatGpt.get_answer(gpt_query) do
            {:ok, answer} ->
              request_word = if remaining_requests == 1, do: "request", else: "requests"

              answer_message =
                answer <> "\n\nYou have *#{remaining_requests}* #{request_word} left today."

              :ok =
                Telegram.send_message(chat.id, answer_message,
                  reply_to_message_id: message_id,
                  parse_mode: "MarkdownV2"
                )

            {:error, _} ->
              :error
          end

        {:limit_reached, _remaining_requests} ->
          :ok =
            Telegram.send_message(chat.id, "You have reached your request limit for today.",
              reply_to_message_id: message_id,
              parse_mode: "MarkdownV2"
            )
      end
    else
      :ok
    end
  end

  defp handle_update(update) do
    IO.inspect(update, label: "Unknown update")
  end

  defp handle_admin_command(command_text, chat, from, message_id) do
    [action, tg_username] = String.split(command_text)
    tg_username = String.replace(tg_username, ~r/^@/, "")

    case action do
      "add" ->
        case UserRequests.add_user_admin(tg_username) do
          {:ok, _} ->
            Telegram.send_message(chat.id, "@#{tg_username} is now an admin.",
              parse_mode: "MarkdownV2",
              reply_to_message_id: message_id
            )

          {:error, _} ->
            Telegram.send_message(chat.id, "User @#{tg_username} not found.",
              parse_mode: "MarkdownV2",
              reply_to_message_id: message_id
            )
        end

      "remove" ->
        case UserRequests.remove_user_admin(tg_username) do
          {:ok, _} ->
            Telegram.send_message(chat.id, "User @#{tg_username} is no longer an admin.",
              parse_mode: "MarkdownV2",
              reply_to_message_id: message_id
            )

          {:error, _} ->
            Telegram.send_message(chat.id, "User @#{tg_username} not found.",
              parse_mode: "MarkdownV2",
              reply_to_message_id: message_id
            )
        end

      _ ->
        Telegram.send_message(chat.id, "Invalid admin command.",
          parse_mode: "MarkdownV2",
          reply_to_message_id: message_id
        )
    end
  end
end
