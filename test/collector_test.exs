defmodule SoccerRankerTest.CollectorTest do
  use ExUnit.Case
  alias SoccerRanker.Collector

  test "report: aggregates passed in points, orders results by points" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Badgers", 1, 0)})
    Collector.add_points({data("Snakes", 3, 2),data("Badgers", 0, -2)})

    results = Collector.report
    [team1, team2] = results.ordered_teams
    assert team1.name == "Snakes"
    assert team1.points == 4
    assert team1.goal_difference == 2
    assert team2.name == "Badgers"
    assert team2.points == 1
    assert team2.goal_difference == -2
  end

  test "report: it sorts by goal difference if points are the same" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 4),data("Badgers", 1, 3)})
    Collector.add_points({data("Anacondas", 1, 2),data("Zebras FC", 1, 1)})

    results = Collector.report
    [team1, team2, team3, team4] = results.ordered_teams

    assert team1.name == "Snakes"
    assert team2.name == "Badgers"
    assert team3.name == "Anacondas"
    assert team4.name == "Zebras FC"
  end

  test "report: it alphabetizes teams with matching scores" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Badgers", 1, 0)})
    Collector.add_points({data("Anacondas", 1, 0),data("Zebras FC", 1, 0)})

    results = Collector.report
    [team1, team2, team3, team4] = results.ordered_teams

    assert team1.name == "Anacondas"
    assert team2.name == "Badgers"
    assert team3.name == "Snakes"
    assert team4.name == "Zebras FC"
  end

  test "report: it returns teams names that have errors" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Elephants", 1, 0)})
    Collector.add_points({data("Snakes", :error), data("Elephants", :error)})
    # add a second set to make sure that we don't repeat the names in the results
    Collector.add_points({data("Snakes", :error), data("Elephants", :error)})

    results = Collector.report

    [team1, team2] = results.ordered_teams
    assert team1.name == "Elephants"
    assert team1.points == 1
    assert team2.name == "Snakes"
    assert team2.points == 1
    assert Enum.sort(results.teams_with_errors) == ["Elephants", "Snakes"]
  end

  test "report_and_rank: it assigns proper rank to each team" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Elephants", 1, 0)})
    Collector.add_points({data("Cougars", 3, 3),data("Badgers", 0, -3)})

    ranks = Collector.report_and_rank
    assert ranks == ["1. Cougars, 3 pts, GD: 3", "2. Elephants, 1 pt, GD: 0", "2. Snakes, 1 pt, GD: 0", "4. Badgers, 0 pts, GD: -3"]
  end

  test "report_and_rank: it includes errors as the last line, if they exist" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Elephants", 1, 0)})
    Collector.add_points({data("Cougars", 3, 3),data("Badgers", 0, -3)})
    Collector.add_points({data("Snakes", :error), data("Elephants", :error)})

    ranks_and_errors = Collector.report_and_rank
    assert ranks_and_errors == ["1. Cougars, 3 pts, GD: 3", "2. Elephants, 1 pt, GD: 0", "2. Snakes, 1 pt, GD: 0", "4. Badgers, 0 pts, GD: -3", "Teams with errors: Elephants, Snakes"]
  end

  test "report_and_rank: it can handle all teams being tied" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Elephants", 1, 0)})
    Collector.add_points({data("Cougars", 1, 0),data("Badgers", 1, 0)})

    ranks = Collector.report_and_rank
    assert ranks == ["1. Badgers, 1 pt, GD: 0", "1. Cougars, 1 pt, GD: 0", "1. Elephants, 1 pt, GD: 0", "1. Snakes, 1 pt, GD: 0"]
  end

  test "report_and_rank: it assigns correct rank after more than two way tie" do
    Collector.start_link
    Collector.add_points({data("Snakes", 1, 0),data("Elephants", 1, 0)})
    Collector.add_points({data("Cougars", 1, 0),data("Badgers", 1, 0)})
    Collector.add_points({data("Bobcats", 0, -1),data("Badgers", 3, 1)})

    ranks = Collector.report_and_rank
    assert ranks == ["1. Badgers, 4 pts, GD: 1", "2. Cougars, 1 pt, GD: 0", "2. Elephants, 1 pt, GD: 0", "2. Snakes, 1 pt, GD: 0", "5. Bobcats, 0 pts, GD: -1"]
  end

  def data(name, points, difference \\ 0) do
    %{name: name, points: points, goal_difference: difference}
  end
end
