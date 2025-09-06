defmodule Mq.Worker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_queue(name) do
    GenServer.cast(__MODULE__, {:create_queue, name})
  end

  def has_queue?(queue_name) do
    GenServer.call(__MODULE__, {:has_queue, queue_name})
  end

  def push(item, priority, queue_name) do
    GenServer.cast(__MODULE__, {:push, priority, item, queue_name})
  end

  def pop() do
    GenServer.call(__MODULE__, {:pop})
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       queue: %Mq.Queue{}
     }}
  end

  @impl true
  def handle_cast({:create_queue, name}, state) do
    new_queue =
      Map.put(state.queue, name, %Mq.Queue{
        subscribers: [],
        messages: Queue.new()
      })

    {:noreply, %{state | queue: new_queue}}
  end

  def handle_cast({:push, priority, item, queue_name}, state) do
    result =
      Mq.Entities.Message.changeset(%Mq.Entities.Message{}, %{
        body: item,
        priority: priority,
        queue: queue_name
      })
      |> Mq.Repo.insert()

    case result do
      {:ok, _message} ->
        new_queue =
          Map.update(state.queue, queue_name, %Mq.Queue{}, fn queue ->
            %Mq.Queue{
              subscribers: queue.subscribers,
              messages: Queue.push(queue.messages, priority, item)
            }
          end)

        {:noreply, %{state | queue: new_queue}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # @impl true
  # def handle_call({:pop}, _from, state) do
  #   # case Queue.pop(state.queue) do
  #   #   {:ok, {_priority, value}, new_queue} ->
  #   #     {:reply, value, %{state | queue: new_queue}}

  #   #   :empty ->
  #   #     {:reply, :empty, state}
  #   # end
  # end

  @impl true
  def handle_call({:has_queue, queue_name}, _from, state) do
    has_queue = Map.has_key?(state.queue, queue_name)
    {:reply, has_queue, state}
  end
end
