defmodule VisionsUnite.StartupTasks do
  alias VisionsUnite.Accounts

  def startup do
    case Accounts.get_user_by_email(System.get_env("SUPERADMIN_EMAIL")) do
      nil ->
        Accounts.register_user(%{
          "email" => System.get_env("SUPERADMIN_EMAIL"),
          "super_admin" => true,
          "password" => System.get_env("SUPERADMIN_PASSWORD")
        })

      _ ->
        IO.puts("Superadmin already exists.")
    end
  end
end
