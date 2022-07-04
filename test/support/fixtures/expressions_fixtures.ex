defmodule VisionsUnite.ExpressionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `VisionsUnite.Expressions` context.
  """

  @doc """
  Generate a expression.
  """
  def expression_fixture(attrs \\ %{}) do
    {:ok, expression} =
      attrs
      |> Enum.into(%{
        body: "some body"
      })
      |> VisionsUnite.Expressions.create_expression()

    expression
  end
end
