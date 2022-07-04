defmodule VisionsUnite.SupportsTest do
  use VisionsUnite.DataCase

  alias VisionsUnite.Supports

  describe "support" do
    alias VisionsUnite.Supports.Support

    import VisionsUnite.SupportsFixtures

    @invalid_attrs %{}

    test "list_support/0 returns all support" do
      support = support_fixture()
      assert Supports.list_support() == [support]
    end

    test "get_support!/1 returns the support with given id" do
      support = support_fixture()
      assert Supports.get_support!(support.id) == support
    end

    test "create_support/1 with valid data creates a support" do
      valid_attrs = %{}

      assert {:ok, %Support{} = support} = Supports.create_support(valid_attrs)
    end

    test "create_support/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Supports.create_support(@invalid_attrs)
    end

    test "update_support/2 with valid data updates the support" do
      support = support_fixture()
      update_attrs = %{}

      assert {:ok, %Support{} = support} = Supports.update_support(support, update_attrs)
    end

    test "update_support/2 with invalid data returns error changeset" do
      support = support_fixture()
      assert {:error, %Ecto.Changeset{}} = Supports.update_support(support, @invalid_attrs)
      assert support == Supports.get_support!(support.id)
    end

    test "delete_support/1 deletes the support" do
      support = support_fixture()
      assert {:ok, %Support{}} = Supports.delete_support(support)
      assert_raise Ecto.NoResultsError, fn -> Supports.get_support!(support.id) end
    end

    test "change_support/1 returns a support changeset" do
      support = support_fixture()
      assert %Ecto.Changeset{} = Supports.change_support(support)
    end
  end
end
