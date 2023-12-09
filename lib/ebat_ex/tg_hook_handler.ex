defmodule Bot42.TgHookHandler do
  use Telegex.Hook.GenHandler

  alias Bot42.Accounts

  @default_tududutu_message "It's Time"

  @impl true
  def on_boot do
    env_config = Application.fetch_env!(:bot42, __MODULE__)

    {:ok, true} = Telegex.delete_webhook()
    {:ok, true} = Telegex.set_webhook(env_config[:webhook_url])

    %Telegex.Hook.Config{server_port: env_config[:server_port]}
  end

  @impl true
  def on_update(%{message: %{from: from, chat: chat, text: text} = message}) do
    Logger.info("Got telegam update with message: #{inspect(message)}")

    case Accounts.get_user_by_tg_username(from.username) do
      nil ->
        :ok

      user ->
        :ok = handle_tududutu_command(text, chat, user)

        :ok
    end
  end

  @spec handle_tududutu_command(String.t() | nil, Telegex.Type.Chat.t(), Accounts.User.t()) :: :ok
  defp handle_tududutu_command("/tududu@tududu_bot", %{id: chat_id}, user) do
    text = user.tududutu_message || @default_tududutu_message

    {:ok, message} = Telegex.send_message(chat_id, text)

    Logger.info("Sent telegam tududu message: #{inspect(message)}")

    :ok
  end

  defp handle_tududutu_command(_text, _chat, _user), do: :ok
end
