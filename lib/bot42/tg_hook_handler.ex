defmodule Bot42.TgHookHandler do
  use Telegex.Hook.GenHandler

  alias Bot42.ChatGpt
  alias Bot42.Telegram
  alias Bot42.DailyAgenda

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

  defp handle_update(%{text: "/gpt" <> text, chat: chat}) do
    with gpt_query <- text |> String.trim_leading("/gpt ") |> String.trim(),
         {:ok, answer} <- ChatGpt.get_answer(gpt_query) do
      :ok = Telegram.send_message(chat.id, answer)
    end

    :ok
  end

  defp handle_update(%{text: "/today" <> text, chat: chat}) do
    IO.inspect(text, label: "Text")
    with {:ok, events_message} <- DailyAgenda.formated_today_events() do
      :ok = Telegram.send_message(chat.id, events_message)
    end

    :ok
  end

  defp handle_update(%{text: "/help" <> _text, chat: chat}) do
    help_message = "HELP: /help for help"

    Telegram.send_message(chat.id, help_message)
  end

  defp handle_update(update) do
    IO.inspect(update, label: "Unknown update")
  end
end
