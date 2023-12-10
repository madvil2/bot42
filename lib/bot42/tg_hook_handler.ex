defmodule Bot42.TgHookHandler do
  use Telegex.Hook.GenHandler

  alias Bot42.Accounts
  alias Bot42.ChatGpt
  alias Bot42.Telegram
  alias Bot42.DailyAgenda

  # Con

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

  def on_update(%{message: %{from: from, chat: chat, text: text} = message}) do
    Logger.info("Got telegam update with message: #{inspect(message)}")

    :ok = handle_user_commands(text, chat)

    :ok
  end

  def handle_user_commands("/test@school42bot", chat), do:
    Telegram.send_message(chat.id, "test passed")

  # def on_update(%{message: %{text: "", from: from, chat: chat} = message}) do
  #
  # end

  # def on_update(%{message: %{new_chat_members: members} = message}) do
  #   Enum.each(members, fn member ->
  #     welcome_message = "Welcome @#{member.username}"
  #     Telegram.send_message(message.chat.id, welcome_message)
  #   end)
  # end



  # def handle_message(%{"text" => "/gpt@school42bot" <> text, "chat" => %{"id" => chat_id}}) do
  #   query =

  #   with {:ok, answer} <- text |> String.trim_leading("/gpt@school42bot ") |> ChatGpt.get_answer(chat_id) do
  #     :ok = Telegram.send_message(chat_id, answer)
  #   end

  #   :ok
  # end

  # @impl true
  # def on_failure(update, error) do
  #   error_message = "Error: #{inspect(error)} processing update: #{inspect(update)}"

  #   Logger.error(error_message)

  #   Telegram.send_message(tg_admin_chat_id(), error_message)
  # end
end
