defmodule Bot42.ChatGpt do
  @no_result_message "No result"

  @spec api_key :: String.t()
  defp api_key do
    :bot42
    |> Application.fetch_env!(:chat_gpt)
    |> Keyword.fetch!(:api_key)
  end

  @spec get_answer(term(), integer()) :: {:ok, String.t()} | {:error, term()}
  def get_answer(query, chat_id) do
    url = "https://api.openai.com/v1/engines/text-davinci-003/completions"

    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      prompt: query,
      max_tokens: 150,
      temperature: 0.7
    }
    |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        text_response =
          response_body
          |> Jason.decode!()
          |> Map.get("choices", [%{"text" => @no_result_message}])
          |> List.first()
          |> Map.get("text")

          {:ok, text_response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
