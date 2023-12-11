defmodule Bot42.ChatGpt do
  @no_result_message "No result"

  @spec api_key :: String.t()
  defp api_key do
    :bot42
    |> Application.fetch_env!(:chat_gpt)
    |> Keyword.fetch!(:api_key)
  end

  def get_answer(query) do
    url = "https://api.openai.com/v1/chat/completions"

    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      model: "gpt-3.5-turbo",
      messages: [
        %{
          role: "system",
          content: "You are a helpful assistant."
        },
        %{
          role: "user",
          content: query
        }
      ]
    }
    |> Jason.encode!()

    IO.inspect(query, label: "Отправленный запрос")
    IO.inspect(body, label: "Тело запроса")
    options = [timeout: 40_000, recv_timeout: 40_000]

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        decoded_response = Jason.decode!(response_body)
        IO.inspect(decoded_response, label: "Ответ API")

        text_response =
          decoded_response
          |> Map.get("choices", [%{"message" => %{"content" => @no_result_message}}])
          |> List.first()
          |> Map.get("message")
          |> Map.get("content")

        {:ok, text_response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
