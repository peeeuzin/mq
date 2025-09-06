defmodule Mq.Queue do
  defstruct [:messages, :subscribers]

  def new() do
    %__MODULE__{
      messages: Queue.new(),
      subscribers: []
    }
  end
end
