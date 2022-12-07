defmodule VisionsUnite.SupportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `VisionsUnite.Supports` context.
  """

  @doc """
  Generate a support.
  """
  def support_fixture(attrs \\ %{}) do
    {:ok, support} =
      attrs
      |> Enum.into(%{})
      |> VisionsUnite.Supports.create_support()

    support
  end
end
