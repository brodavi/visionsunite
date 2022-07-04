defmodule VisionsUnite.ExpressionsTest do
  use VisionsUnite.DataCase

  alias VisionsUnite.Expressions

  describe "expressions" do
    alias VisionsUnite.Expressions.Expression

    import VisionsUnite.ExpressionsFixtures

    @invalid_attrs %{body: nil}

    test "list_expressions/0 returns all expressions" do
      expression = expression_fixture()
      assert Expressions.list_expressions() == [expression]
    end

    test "get_expression!/1 returns the expression with given id" do
      expression = expression_fixture()
      assert Expressions.get_expression!(expression.id) == expression
    end

    test "create_expression/1 with valid data creates a expression" do
      valid_attrs = %{body: "some body"}

      assert {:ok, %Expression{} = expression} = Expressions.create_expression(valid_attrs)
      assert expression.body == "some body"
    end

    test "create_expression/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Expressions.create_expression(@invalid_attrs)
    end

    test "update_expression/2 with valid data updates the expression" do
      expression = expression_fixture()
      update_attrs = %{body: "some updated body"}

      assert {:ok, %Expression{} = expression} = Expressions.update_expression(expression, update_attrs)
      assert expression.body == "some updated body"
    end

    test "update_expression/2 with invalid data returns error changeset" do
      expression = expression_fixture()
      assert {:error, %Ecto.Changeset{}} = Expressions.update_expression(expression, @invalid_attrs)
      assert expression == Expressions.get_expression!(expression.id)
    end

    test "delete_expression/1 deletes the expression" do
      expression = expression_fixture()
      assert {:ok, %Expression{}} = Expressions.delete_expression(expression)
      assert_raise Ecto.NoResultsError, fn -> Expressions.get_expression!(expression.id) end
    end

    test "change_expression/1 returns a expression changeset" do
      expression = expression_fixture()
      assert %Ecto.Changeset{} = Expressions.change_expression(expression)
    end
  end
end
