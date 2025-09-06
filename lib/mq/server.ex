defmodule Mq.Server do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} = Task.Supervisor.start_child(Mq.Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(client) do
    client
    |> read_line()
    |> execute(client)

    serve(client)
  end

  defp read_line(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        data

      {:error, :closed} ->
        :closed
    end
  end

  defp execute(data, client) when is_binary(data) do
    data
    |> String.trim()
    |> String.split(":")
    |> handle_command(client)
  end

  defp handle_command(["CREATE", queue_name], client) do
    if !Mq.Worker.has_queue?(queue_name) do
      Mq.Worker.create_queue(queue_name)
      :gen_tcp.send(client, "OK\n")
    else
      :gen_tcp.send(client, "ERROR: Queue already exists\n")
    end
  end

  defp handle_command(["PUSH", priority, queue_name, item], client) do
    if Mq.Worker.has_queue?(queue_name) do
      Mq.Worker.push(item, String.to_existing_atom(priority), queue_name)
      :gen_tcp.send(client, "OK\n")
    else
      :gen_tcp.send(client, "ERROR: Queue does not exist\n")
    end
  end

  defp handle_command(_, client) do
    :gen_tcp.send(client, "ERROR: Unknown command\n")
  end
end
