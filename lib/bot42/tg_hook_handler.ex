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
  defp handle_update(%{text: "/gpt" <> text, chat: chat, from: from, message_id: message_id}) do
    case UserRequests.check_and_update_requests(from.id) do
      {:ok, remaining_requests} ->
        gpt_query = text |> String.trim_leading("/gpt ") |> String.trim()

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

    if UserRequests.is_user_admin(from.id) or admin_chat_id == chat.id do
      handle_admin_command(rest, chat, from, message_id)
    else
      Telegram.send_message(
        chat.id,
        "Only admins can use admin commands, or use in the admin chat.",
        reply_to_message_id: message_id
      )
    end
  end

  defp handle_admin_command(command_text, chat, from, message_id) do
    [action, username] = String.split(command_text)

    case action do
      "add" ->
        UserRequests.add_user_admin(from.id)

      "remove" ->
        UserRequests.remove_user_admin(from.id)

      _ ->
        Telegram.send_message(chat.id, "Invalid admin command.", reply_to_message_id: message_id)
    end
  end

  defp handle_update(update) do
    IO.inspect(update, label: "Unknown update")
  end
end
