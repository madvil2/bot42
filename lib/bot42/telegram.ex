defmodule Bot42.Telegram do
  @spec send_message(integer(), String.t()) :: :ok
  def send_message(chat_id, message) do
    options = [parse_mode: "MarkdownV2"]

    {:ok, _message} = Telegex.send_message(chat_id, message, options)

    :ok
  end
end
