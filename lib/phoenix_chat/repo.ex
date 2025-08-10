defmodule PhoenixChat.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_chat,
    adapter: Ecto.Adapters.SQLite3
end
