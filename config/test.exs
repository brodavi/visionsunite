import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :visions_unite, VisionsUnite.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "visions_unite_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :visions_unite, VisionsUniteWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dUlSY/EW1kPZ7AJpMnZLG9rl+JB2pprJvw8Ypv3fDEAXEeLfI+WVq/lWXvaNu25y",
  server: false

# In test we don't send emails.
config :visions_unite, VisionsUnite.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
