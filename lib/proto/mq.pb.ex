defmodule Mq.Proto.NewEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :queue_name, 1, type: :string, json_name: "queueName"
  field :event_kind, 2, type: :string, json_name: "eventKind"
  field :data, 3, type: :bytes
end

defmodule Mq.Proto.MessageItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :string
  field :data, 2, type: :bytes
  field :inserted_at, 3, type: Google.Protobuf.Timestamp, json_name: "insertedAt"
  field :updated_at, 4, type: Google.Protobuf.Timestamp, json_name: "updatedAt"
end
