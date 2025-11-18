defmodule Mq.Worker do
  use GenServer
  import Ecto.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_queue(name) do
    GenServer.call(__MODULE__, {:create_queue, name})
  end

  def has_queue?(queue_name) do
    GenServer.call(__MODULE__, {:has_queue, queue_name})
  end

  def push(item, queue_name) do
    GenServer.call(__MODULE__, {:push, item, queue_name})
  end

  def subscribe(queue_name, subscriber) do
    GenServer.cast(__MODULE__, {:subscribe, queue_name, subscriber})
  end

  defp spawn_event(event_kind, queue_name, data) do
    GenServer.cast(__MODULE__, {:event, event_kind, queue_name, data})
  end

  #
  # GenServer callbacks
  #

  @impl true
  def init(_opts) do
    queue =
      Mq.Repo.all(Mq.Entities.Queue)
      |> Enum.map(fn q ->
        messages =
          Mq.Repo.all(
            from(
              m in Mq.Entities.Message,
              where: m.queue_id == ^q.id,
              select: m.body,
              order_by: [asc: m.inserted_at]
            )
          )
          |> :queue.from_list()

        {q.name, %Mq.Queue{subscribers: [], messages: messages}}
      end)
      |> Enum.into(%{})

    {:ok,
     %{
       queue: queue
     }}
  end

  #
  # Queue operations
  #

  # Create queue
  @impl true
  def handle_call({:create_queue, name}, _from, state) do
    result =
      Mq.Entities.Queue.changeset(%Mq.Entities.Queue{}, %{
        name: name
      })
      |> Mq.Repo.insert()

    case result do
      {:ok, _queue} ->
        new_queue =
          Map.put(state.queue, name, %Mq.Queue{
            subscribers: [],
            messages: :queue.new()
          })

        {:reply, :ok, %{state | queue: new_queue}}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  # Push a message to queue
  @impl true
  def handle_call({:push, body, queue_name}, _from, state) do
    queue = Mq.Repo.get_by(Mq.Entities.Queue, name: queue_name)

    result =
      Mq.Entities.Message.changeset(%Mq.Entities.Message{}, %{
        body: body,
        queue_id: queue.id
      })
      |> Mq.Repo.insert()

    case result do
      {:ok, message} ->
        item = %Mq.Queue.MessageItem{
          id: message.id,
          body: body,
          ack: message.ack,
          inserted_at: message.inserted_at,
          updated_at: message.updated_at
        }

        new_queue =
          Map.update(state.queue, queue_name, %Mq.Queue{}, fn queue ->
            %Mq.Queue{
              subscribers: queue.subscribers,
              messages: :queue.in(item, queue.messages)
            }
          end)

        spawn_event(:message_pushed, queue_name, item)

        {:reply, :ok, %{state | queue: new_queue}}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  # Check if queue exists
  @impl true
  def handle_call({:has_queue, queue_name}, _from, state) do
    has_queue = Map.has_key?(state.queue, queue_name)
    {:reply, has_queue, state}
  end

  # Subscribe to a queue
  @impl true
  def handle_cast({:subscribe, queue_name, subscriber}, state) do
    new_queue =
      Map.update(state.queue, queue_name, %Mq.Queue{}, fn queue ->
        %Mq.Queue{
          subscribers: [subscriber | queue.subscribers],
          messages: queue.messages
        }
      end)

    spawn_event(:new_subscriber, queue_name, subscriber)

    {:noreply, %{state | queue: new_queue}}
  end

  # @impl true
  # def handle_cast({:ack, queue_name, subscriber}, state) do
  #   {:noreply, %{state | queue: new_queue}}
  # end

  # Events

  # Message pushed event
  @impl true
  def handle_cast({:event, :message_pushed, queue_name, item}, state) do
    queue = Map.get(state.queue, queue_name)

    data = Mq.Proto.MessageItem.encode(item |> Mq.Queue.MessageItem.to_proto())

    Enum.each(queue.subscribers, fn subscriber ->
      send_event_to_subscriber(subscriber, "message_pushed", queue_name, data)
    end)

    {:noreply, state}
  end

  # New subscriber event
  @impl true
  def handle_cast({:event, :new_subscriber, queue_name, subscriber}, state) do
    queue = Map.get(state.queue, queue_name)

    Enum.each(:queue.to_list(queue.messages), fn message ->
      send_event_to_subscriber(subscriber, "message_pushed", queue_name, message)
    end)

    {:noreply, state}
  end

  # Helper functions

  defp send_event_to_subscriber(subscriber, event_kind, queue_name, message) do
    msg = %Mq.Proto.NewEvent{
      queue_name: queue_name,
      event_kind: event_kind,
      data: message
    }

    :gen_tcp.send(
      subscriber,
      msg |> Mq.Proto.NewEvent.encode()
    )
  end
end
