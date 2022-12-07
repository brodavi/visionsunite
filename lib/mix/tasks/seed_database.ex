defmodule Mix.Tasks.SeedDatabase do
  @moduledoc """
  Seeding the database
  """
  use Mix.Task

  alias VisionsUnite.Accounts
  alias VisionsUnite.Expressions
  alias VisionsUnite.Supports
  alias VisionsUnite.ExpressionSubscriptions

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    if System.get_env("ENV") != "production" do
      #
      # TODO
      #
      # I think I'd like to do tests here... and why not? Set up a viable app state using
      # high-level commands (from liveview? controllers?) that triggers lots of flows.
      # If I seed the database and everything works, I can feel pretty confident everything
      # works. Then I can play around and dev too.
      #

      # Create 6 new users
      1..6
      |> Enum.each(fn x ->
        Accounts.register_user(%{
          "email" => "testuser#{x}@test.test",
          "password" => System.get_env("SUPERADMIN_PASSWORD")
        })
      end)

      #
      # Create some expressions
      #

      # Create a root expression of food
      {:ok, _expression, sortition_maps_1} =
        Expressions.create_expression(
          %{
            author_id: 2,
            title: "food",
            body: "topic of food"
          },
          []
        )

      # Create a root expression of philosophy
      {:ok, _expression, sortition_maps_2} =
        Expressions.create_expression(
          %{
            author_id: 2,
            title: "philosophy",
            body: "topic of philosophy"
          },
          []
        )

      # Create a root expression of capitalism
      {:ok, _expression, sortition_maps_3} =
        Expressions.create_expression(
          %{
            author_id: 3,
            title: "capitalism",
            body: "topic of capitalism"
          },
          []
        )

      # Create a root expression of chaos
      {:ok, _expression, sortition_maps_4} =
        Expressions.create_expression(
          %{
            author_id: 4,
            title: "chaos",
            body: "topic of chaos"
          },
          []
        )

      # Create a root expression of love
      {:ok, _expression, sortition_maps_5} =
        Expressions.create_expression(
          %{
            author_id: 5,
            title: "love",
            body: "topic of love"
          },
          []
        )

      # For every user in sortition_maps_1, support expression 1 (food)
      sortition_maps_1
      |> Enum.each(fn sortition_map ->
        group_id =
          sortition_map
          |> Map.keys()
          |> List.first()

        Map.get(sortition_map, group_id)
        |> Enum.each(fn user_id ->
          Supports.create_support(%{
            support: 1,
            note: "user #{user_id} likes food",
            user_id: user_id,
            expression_id: 1,
            for_group_id: group_id
          })
        end)
      end)

      # For every user in sortition_maps_2, don't support expression 2 (philosophy)
      sortition_maps_2
      |> Enum.each(fn sortition_map ->
        group_id =
          sortition_map
          |> Map.keys()
          |> List.first()

        Map.get(sortition_map, group_id)
        |> Enum.each(fn user_id ->
          Supports.create_support(%{
            support: 0,
            note: "user #{user_id} does not support philosophy",
            user_id: user_id,
            expression_id: 2,
            for_group_id: nil
          })
        end)
      end)

      # For every user in sortition_maps_3, reject expression 3 (capitalism)
      sortition_maps_3
      |> Enum.each(fn sortition_map ->
        group_id =
          sortition_map
          |> Map.keys()
          |> List.first()

        Map.get(sortition_map, group_id)
        |> Enum.each(fn user_id ->
          Supports.create_support(%{
            support: -1,
            note: "user #{user_id} rejects capitalism",
            user_id: user_id,
            expression_id: 3,
            for_group_id: nil
          })
        end)
      end)

      # For every user in sortition_maps_4, randomly support or not support or reject expression 4 (chaos)
      sortition_maps_4
      |> Enum.each(fn sortition_map ->
        group_id =
          sortition_map
          |> Map.keys()
          |> List.first()

        Map.get(sortition_map, group_id)
        |> Enum.each(fn user_id ->
          random =
            case :rand.uniform(3) do
              1 -> -1
              2 -> 0
              3 -> 1
            end

          Supports.create_support(%{
            support: random,
            note: "user #{user_id} #{random}'s chaos",
            user_id: user_id,
            expression_id: 4,
            for_group_id: nil
          })
        end)
      end)

      # For every user in sortition_maps_5, support expression 5 (love)
      sortition_maps_5
      |> Enum.each(fn sortition_map ->
        group_id =
          sortition_map
          |> Map.keys()
          |> List.first()

        Map.get(sortition_map, group_id)
        |> Enum.each(fn user_id ->
          Supports.create_support(%{
            support: 1,
            note: "user #{user_id} likes love",
            user_id: user_id,
            expression_id: 5,
            for_group_id: nil
          })
        end)
      end)

      # Let's say three users have subscribed to the first fully supported expression (food)
      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 1,
        user_id: 3,
        subscribe: true
      })

      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 1,
        user_id: 4,
        subscribe: true
      })

      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 1,
        user_id: 5,
        subscribe: true
      })

      # And let's say three other users have subscribed to the second fully supported expression (love)
      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 5,
        user_id: 6,
        subscribe: true
      })

      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 5,
        user_id: 2,
        subscribe: true
      })

      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 5,
        user_id: 3,
        subscribe: true
      })

      # Now create expressions "under" these root expressions
      Expressions.create_expression(
        %{
          author_id: 2,
          # expression #6
          title: "diogenes",
          body: "topic of diogenes"
        },
        [2]
      )

      # NOTE!!! diogenes should not result in ANYONE being sought for support
      #   because #philosophy is NOT a supported expression
      Expressions.create_expression(
        %{
          author_id: 2,
          # expression #7
          title: "pizza",
          body: "topic of pizza"
        },
        [1]
      )

      Expressions.create_expression(
        %{
          author_id: 2,
          # expression #8
          title: "the love of food",
          body: "topic with double linkage"
        },
        [1, 5]
      )

      # Let's say user 3 (testuser2@test.test) ignores "love"
      ExpressionSubscriptions.create_expression_subscription(%{
        expression_id: 5,
        user_id: 3,
        subscribe: false
      })

      # At this point, there should be 6 users, 2 fully-supported root expressions, a not-supported, a rejected, and an unknown mixed random expression, and "pizza" and "love of food" seeking supports. Also, user 3 should ignore "love"
    end
  end
end
