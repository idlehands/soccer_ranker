defmodule SoccerRankerTest.ResultParserTest do
  use ExUnit.Case
  alias SoccerRanker.ResultParser

  test "it returns 1 point for teams that tie" do
    {team1, team2} = ResultParser.points("Lions 3, Snakes 3")
    assert team1.name == "Lions"
    assert team1.points == 1
    assert team1.goal_difference == 0
    assert team2.name == "Snakes"
    assert team2.points == 1
    assert team2.goal_difference == 0
  end

  test "returns 3 points for a win, 0 for a loss" do
    {team1, team2} = ResultParser.points("Lions 2, Snakes 1")
    assert team1.name == "Lions"
    assert team1.points == 3
    assert team1.goal_difference == 1
    assert team2.name == "Snakes"
    assert team2.points == 0
    assert team2.goal_difference == -1
  end

  test "works independent of input order (losing team first)" do
    {team1, team2} = ResultParser.points("Lions 1, Snakes 2")
    assert team1.name == "Lions"
    assert team1.points == 0
    assert team1.goal_difference == -1
    assert team2.name == "Snakes"
    assert team2.points == 3
    assert team2.goal_difference == 1
  end

  test "it handles spaces in the team name" do
    {team1, _team2} = ResultParser.points("Long Team Name 3, Snakes 3")
    assert team1.name == "Long Team Name"
  end

  test "it returns error when score is not included in input" do
    {team1, team2} = ResultParser.points("Lions, Snakes")

    assert team1.name == "Lions"
    assert team1.points == :error
    assert team1.goal_difference == 0
    assert team2.name == "Snakes"
    assert team2.points == :error
    assert team2.goal_difference == 0
  end
end
