import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/bot42 start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :bot42, Bot42Web.Endpoint, server: true
end

tg_webhook_url = System.fetch_env!("TG_WEBHOOK_URL")
tg_webhook_server_port = System.fetch_env!("TG_WEBHOOK_SERVER_PORT")

config :bot42, Bot42.TgHookHandler,
  webhook_url: tg_webhook_url,
  server_port: String.to_integer(tg_webhook_server_port)

chat_gpt_api_key = System.fetch_env!("CHAT_GPT_API_KEY")

config :bot42, :chat_gpt, api_key: chat_gpt_api_key

tg_admin_chat_id = "TELEGRAM_ADMIN_CHAT_ID" |> System.fetch_env!() |> String.to_integer()

config :bot42, :telegram, admin_chat_id: tg_admin_chat_id

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :bot42, Bot42.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :bot42, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
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
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 80
    ],
    secret_key_base: secret_key_base
end
