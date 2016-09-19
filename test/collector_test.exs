defmodule SoccerRankerTest.CollectorTest do
  use ExUnit.Case
  alias SoccerRanker.Collector

  test "report: aggregates passed in points, orders results by points" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1},{"Badgers", 1}})
    Collector.add_points({{"Snakes", 3},{"Badgers", 0}})

    results = Collector.report

    assert results.ordered_teams == [{"Snakes", 4}, {"Badgers", 1}]
  end

  test "report: it alphabetizes teams with matching scores" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1},{"Badgers", 1}})
    Collector.add_points({{"Anacondas", 1},{"Zebras FC", 1}})

    results = Collector.report

    assert results.ordered_teams == [{"Anacondas", 1},{"Badgers", 1}, {"Snakes", 1}, {"Zebras FC", 1}]
  end

  test "report: it returns teams names that have errors" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1}, {"Elephants", 1}})
    Collector.add_points({{"Snakes", :error}, {"Elephants", :error}})
    # add a second set to make sure that we don't repeat the names in the results
    Collector.add_points({{"Snakes", :error}, {"Elephants", :error}})
    results = Collector.report

    assert results.ordered_teams == [{"Elephants", 1}, {"Snakes", 1}]
    assert Enum.sort(results.teams_with_errors) == ["Elephants", "Snakes"]
  end

  test "report_and_rank: it assigns proper rank to each team" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1}, {"Elephants", 1}})
    Collector.add_points({{"Cougars", 3},{"Badgers", 0}})

    ranks = Collector.report_and_rank
    assert ranks == ["1. Cougars, 3 pts", "2. Elephants, 1 pt", "2. Snakes, 1 pt", "4. Badgers, 0 pts"]
  end

  test "report_and_rank: it includes errors as the last line, if they exist" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1}, {"Elephants", 1}})
    Collector.add_points({{"Cougars", 3},{"Badgers", 0}})
    Collector.add_points({{"Snakes", :error}, {"Elephants", :error}})

    ranks_and_errors = Collector.report_and_rank
    assert ranks_and_errors == ["1. Cougars, 3 pts", "2. Elephants, 1 pt", "2. Snakes, 1 pt", "4. Badgers, 0 pts", "Teams with errors: Elephants, Snakes"]
  end
end
