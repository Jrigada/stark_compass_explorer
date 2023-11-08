import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :starknet_explorer, StarknetExplorerWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: StarknetExplorer.Finch

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name:
    if(System.get_env("SENTRY_ENV") == "production", do: :production, else: :testing),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: System.get_env("SENTRY_ENV"),
    runtime: "elixir"
  },
  included_environments: [
    if(System.get_env("SENTRY_ENV") == "production", do: :production, else: :testing)
  ]
