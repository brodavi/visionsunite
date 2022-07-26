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

        1..6
        |> Enum.each(fn x ->
          # Create 6 new users
          Accounts.register_user(%{
            "email" => "testuser#{x}@test.test",
            "password" => System.get_env("SUPERADMIN_PASSWORD")
          })
        end)

      _ ->
        IO.puts "Superadmin already exists."
    end
  end
end

