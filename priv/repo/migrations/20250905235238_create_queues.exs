defmodule Mq.Repo.Migrations.CreateQueues do
  use Ecto.Migration

  def change do
    create table(:queues, primary_key: false) do
      add :id, :binary_id, primary_key: true, autogenerate: true
      add :name, :string, null: false, unique: true

      timestamps()
    end

    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true, autogenerate: true
      add :queue_id, references(:queues, on_delete: :delete_all), null: false
      add :body, :binary, null: false
      add :ack, :boolean, default: false, null: false

      timestamps()
    end
  end
end
