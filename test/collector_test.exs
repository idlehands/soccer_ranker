defmodule SoccerRankerTest.CollectorTest do
  use ExUnit.Case
  alias SoccerRanker.Collector

  test "aggregates passed in points, orders results by points" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1},{"Badgers", 1}})
    Collector.add_points({{"Snakes", 3},{"Badgers", 0}})

    results = Collector.report

    assert results.ordered_teams == [{"Snakes", 4}, {"Badgers", 1}]
  end

  test "it alphabetizes teams with matching scores" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1},{"Badgers", 1}})
    Collector.add_points({{"Anacondas", 1},{"Zebras FC", 1}})

    results = Collector.report

    assert results.ordered_teams == [{"Anacondas", 1},{"Badgers", 1}, {"Snakes", 1}, {"Zebras FC", 1}]
  end

  test "it returns teams names that have errors" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1}, {"Elephants", 1}})
    Collector.add_points({{"Snakes", :error}, {"Elephants", :error}})
    # add a second set to make sure that we don't repeat the names in the results
    Collector.add_points({{"Snakes", :error}, {"Elephants", :error}})
    results = Collector.report

    assert results.ordered_teams == [{"Elephants", 1}, {"Snakes", 1}]
    assert Enum.sort(results.teams_with_errors) == ["Elephants", "Snakes"]
  end
end
