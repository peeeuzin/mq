defmodule Mq.Entities.Queue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "queues" do
    field :name, :string

    timestamps()
  end

  def changeset(queue, attrs \\ %{}) do
    queue
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
