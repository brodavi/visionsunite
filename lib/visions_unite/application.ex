defmodule VisionsUnite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      VisionsUnite.Repo,
      # Start the Telemetry supervisor
      VisionsUniteWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: VisionsUnite.PubSub},
      # Start the Endpoint (http/https)
      VisionsUniteWeb.Endpoint,
      # Start a worker by calling: VisionsUnite.Worker.start_link(arg)
      # {VisionsUnite.Worker, arg}
      {Task, &VisionsUnite.StartupTasks.startup/0},
      {Finch, name: Swoosh.Finch},
      {Task.Supervisor, name: VisionsUnite.MySupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VisionsUnite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VisionsUniteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
