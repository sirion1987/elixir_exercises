defmodule TcpServer.Command do
  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> TcpServer.Command.parse("HELP")
      {:ok, {:help}}
  """
  def parse(line) do
    case String.split(line) do
      ["HELP"] -> {:ok, {:help}}
      ["SHOUT" | message] -> {:ok, {:shout, Enum.join(message, " ")}}
      ["SEND", receiver | message] -> {:ok, {:send, receiver, Enum.join(message, " ")}}
      _ -> {:error, :unknown_command}
    end
  end

  def run({:help}) do
    {:ok, help_message()}
  end

  def run({:shout, message}) do
    {:ok, :broadcast, message}
  end

  def run({:send, receiver, message}) do
    {:ok, :p2p, receiver, message}
  end

  defp help_message do
    ~S"""
    TCPServer.

    HELP: print this help.
    SHOUT <MSG> send messagge in broadcast
    """
  end
end
