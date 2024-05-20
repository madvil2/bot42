import Config

if System.get_env("PHX_SERVER") do
  config :bot42, Bot42Web.Endpoint, server: true
end

# Telegram configuration
tg_webhook_url = System.fetch_env!("TG_WEBHOOK_URL")
tg_webhook_server_port = System.fetch_env!("TG_WEBHOOK_SERVER_PORT")
telegram_admin_chat_id = System.fetch_env!("TELEGRAM_ADMIN_CHAT_ID")

config :bot42, Bot42.TgHookHandler,
  webhook_url: tg_webhook_url,
  server_port: String.to_integer(tg_webhook_server_port),
  admin_chat_id: String.to_integer(telegram_admin_chat_id)

# ChatGPT configuration
chat_gpt_api_key = System.fetch_env!("CHAT_GPT_API_KEY")
config :bot42, :chat_gpt, api_key: chat_gpt_api_key

# Calendar URLs
calendar_intra_url = System.fetch_env!("CALENDAR_INTRA_URL")
calendar_fablab_url = System.fetch_env!("CALENDAR_FABLAB_URL")
calendar_mycustom_url = System.fetch_env!("CALENDAR_MYCUSTOM_URL")

config :bot42, :calendar_urls,
  intra_url: calendar_intra_url,
  fablab_url: calendar_fablab_url,
  mycustom_url: calendar_mycustom_url

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :bot42, Bot42.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :bot42, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.fetch_env!("HOST")

  config :bot42, Bot42Web.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 80
    ],
    secret_key_base: secret_key_base
end
