defmodule Bot42.Telegram do
  @spec send_message(integer(), String.t(), keyword() | nil) :: :ok
  def send_message(chat_id, message, opts \\ []) do
    safe_message = Phoenix.HTML.Safe.to_iodata(message)
    {:ok, _message} = Telegex.send_message(chat_id, safe_message, opts)

    :ok
  end
end
