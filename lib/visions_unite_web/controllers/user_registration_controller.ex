defmodule VisionsUniteWeb.UserRegistrationController do
  use VisionsUniteWeb, :controller

  alias VisionsUnite.Accounts
  alias VisionsUnite.Accounts.User
  alias VisionsUniteWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        ### Getting rid of user confirmation step for now

        # {:ok, _} =
        #   Accounts.deliver_user_confirmation_instructions(
        #     user,
        #     &Routes.user_confirmation_url(conn, :edit, &1)
        #   )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
