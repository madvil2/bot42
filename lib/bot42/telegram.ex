defmodule Bot42.Telegram do
  require Logger

  @spec send_message(integer(), String.t(), keyword() | nil) :: :ok | {:error, term()}
  def send_message(chat_id, message, opts \\ []) do
    case Telegex.send_message(chat_id, escape_telegram(message), opts) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        log_and_notify_error(reason, %{chat_id: chat_id, message: message, opts: opts})
        {:error, reason}
    end
  end

  @spec escape_telegram(String.t()) :: String.t()
  defp escape_telegram(str) do
    str
    |> String.replace("#", "\\#")
    |> String.replace("-", "\\-")
    |> String.replace(".", "\\.")
    |> String.replace("!", "\\!")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
  end

  defp log_and_notify_error(error, update) do
    error_message = "Error sending message: #{inspect(error)} for update: #{inspect(update)}"
    Logger.error(error_message)
    Bot42.TgHookHandler.on_failure(update, error)
  end
end
