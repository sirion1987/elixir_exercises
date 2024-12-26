defmodule TcpServer.UserRegistry do
  use GenServer

  require Logger

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, server, opts)
  end

  @impl true
  def init(_init_arg) do
    names = :ets.new(:users_lookup, [:public, :named_table])
    refs = %{}

    Logger.info("INIT UserRegistry")

    {:ok, {names, refs}}
  end

  def insert({username, socket}) do
    :ets.insert(:users_lookup, {username, socket})
  end

  def delete(socket) do
    %{username: username, socket: _} = get_by_socket(socket)
    :ets.delete(:users_lookup, username)
  end

  def get_by_socket(socket) do
    [{username, socket}] = :ets.match_object(:users_lookup, {:"$1", socket})

    %{username: username, socket: socket}
  end

  def get_by_username(username) do
    [{username, socket}] = :ets.match_object(:users_lookup, {username, :"$1"})

    %{username: username, socket: socket}
  end

  def list do
    :ets.match(:users_lookup, :"$1")
  end
end
