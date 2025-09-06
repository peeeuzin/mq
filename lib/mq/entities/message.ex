defmodule Mq.Entities.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "messages" do
    field :body, :binary
    belongs_to :queue, Mq.Entities.Queue

    timestamps()
  end

  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [:body, :queue_id])
    |> validate_required([:body, :queue_id])
  end
end
