defmodule Bot42.Telegram do
    @spec send_message(integer(), String.t()) :: :ok
    def send_message(chat_id, message) do
      {:ok, _message} = Telegex.send_message(chat_id, message)

      :ok
    end
end
