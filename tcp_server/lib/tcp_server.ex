defmodule TcpServer do
  require Logger

  alias TcpServer.UserRegistry, as: UserRegistry

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")

    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(TcpServer.TaskSupervisor, fn -> init(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp init(socket) do
    do_send(socket, {:ok, "Hello. Choose an username: "})

    case do_read(socket) do
      {:ok, raw_username} ->
        username = String.trim(raw_username)

        Logger.info("[START] #{username}")
        UserRegistry.insert({username, socket})
        do_send(socket, {:ok, "\r\n>"})
        serve(socket)

      {:error, :closed} ->
        exit(:shutdown)
    end
  end

  defp serve(socket) do
    msg =
      with {:ok, data} <- do_read(socket),
           {:ok, command} <- TcpServer.Command.parse(data),
           do: TcpServer.Command.run(command)

    do_send(socket, msg)
    serve(socket)
  end

  defp do_read(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp do_send(socket, {:ok, :broadcast, text}) do
    %{username: sender, socket: _} = UserRegistry.get_by_socket(socket)
    userList = UserRegistry.list()

    Enum.each(userList, fn [{_, user_socket}] ->
      if user_socket != socket,
        do: do_send(user_socket, {:ok, "[#{sender}] > \"#{text}\"\r\n>"})
    end)
  end

  defp do_send(socket, {:ok, :p2p, receiver, message}) do
    %{username: sender, socket: _} = UserRegistry.get_by_socket(socket)
    %{username: _, socket: receiver_socket} = UserRegistry.get_by_username(receiver)

    do_send(receiver_socket, {:ok, "[#{sender}] > \"#{message}\"\r\n>"})
  end

  defp do_send(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp do_send(socket, {:error, :unknown_command}) do
    # Known error; write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n>")
  end

  defp do_send(socket, {:error, :closed}) do
    # The connection was closed, exit politely
    UserRegistry.delete(socket)
    exit(:shutdown)
  end

  defp do_send(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "ERROR\r\n>")
    UserRegistry.delete(socket)
    exit(error)
  end
end
