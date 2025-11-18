defmodule Mq.MixProject do
  use Mix.Project

  def project do
    [
      app: :mq,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Mq.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sqlite3, "~> 0.21"},
      {:ecto_sql, "~> 3.13"},
      {:protobuf, "~> 0.15.0"}
    ]
  end

  defp aliases do
    [
      "proto.gen": ["cmd protoc --elixir_out=./lib proto/mq.proto"],
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"]
    ]
  end
end
