defmodule Mq.Repo do
  use Ecto.Repo,
    otp_app: :mq,
    adapter: Ecto.Adapters.SQLite3
end
