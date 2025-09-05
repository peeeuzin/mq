defmodule Mq.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("MQ_PORT") || "6932")

    children = [
      {Mq.Worker, []},
      {Task.Supervisor, name: Mq.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Mq.Server.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Mq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
