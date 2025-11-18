defmodule Mq.Queue do
  defstruct [:messages, :subscribers]

  def new() do
    %__MODULE__{
      messages: :queue.new(),
      subscribers: []
    }
  end
end

defmodule Mq.Queue.MessageItem do
  defstruct [:id, :body, :ack, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          body: binary(),
          ack: boolean(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  def to_proto(%__MODULE__{id: id, body: body, inserted_at: inserted_at, updated_at: updated_at}) do
    %Mq.Proto.MessageItem{
      id: id,
      data: body,
      inserted_at: inserted_at,
      updated_at: updated_at
    }
  end
end
