defmodule Mq.Worker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok,
     %{
       queue: Queue.new()
     }}
  end

  def push(item) do
    GenServer.cast(__MODULE__, {:push, item})
  end

  def pop() do
    GenServer.call(__MODULE__, {:pop})
  end

  def handle_cast({:push, item}, _from, state) do
    new_queue = Queue.push(state.queue, :high, item)
    {:noreply, %{state | queue: new_queue}}
  end

  def handle_call({:pop}, state) do
    case Queue.pop(state.queue) do
      {:ok, {_priority, value}, new_queue} ->
        {:reply, value, %{state | queue: new_queue}}

      :empty ->
        {:reply, :empty, state}
    end
  end
end
