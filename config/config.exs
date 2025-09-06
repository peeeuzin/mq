import Config

config :mq,
  ecto_repos: [Mq.Repo]

config :mq, Mq.Repo, database: "mqdb.db"
