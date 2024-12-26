defmodule TcpServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4000")

    children = [
      {Task.Supervisor, name: TcpServer.TaskSupervisor},
      {TcpServer.UserRegistry, name: TcpServer.UserRegistry},
      Supervisor.child_spec({Task, fn -> TcpServer.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: TcpServer.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
