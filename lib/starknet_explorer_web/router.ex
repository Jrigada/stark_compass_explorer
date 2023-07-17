defmodule StarknetExplorerWeb.Router do
  use StarknetExplorerWeb, :router
  alias Plug.Conn

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StarknetExplorerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug :network_selector
  end

  def network_selector(conn = %Conn{}, _opts) do
    case conn.path_params do
      %{"network" => network} when network in ["mainnet", "testnet", "testnet2"] ->
        network =
          network
          |> String.to_existing_atom()

        conn
        |> assign(:network, network)

      _ ->
        conn
        |> redirect(to: "/mainnet")
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default, on_mount: {StarknetExplorerWeb.Live.CommonAssigns, :network} do
    scope "/:network", StarknetExplorerWeb do
      pipe_through :browser

      live "/", HomeLive.Index, :index
      live "/blocks", BlockIndexLive
      live "/block/:number_or_hash", BlockDetailLive
      live "/transactions", TransactionIndexLive
      live "/transactions/:transaction_hash", TransactionLive
      live "/contracts", ContractIndexLive
      live "/contracts/:address", ContractDetailLive
      live "/events", EventIndexLive
      live "/events/:identifier", EventDetailLive
      live "/messages", MessageIndexLive
      live "/messages/:identifier", MessageDetailLive
      live "/classes", ClassIndexLive
      live "/classes/:hash", ClassDetailLive
    end

    forward "/", StarknetExplorerWeb.Plug.Redirect
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:starknet_explorer, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StarknetExplorerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
