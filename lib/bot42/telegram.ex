defmodule Bot42.Telegram do
    @spec send_message(integer(), String.t(), String.t()) :: :ok
    def send_message(chat_id, message, opts \\ []) do
      {:ok, _message} = Telegex.send_message(chat_id, message, opts)

      :ok
    end
end
