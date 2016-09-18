defmodule SoccerRankerTest.ResultParserTest do
  use ExUnit.Case
  alias SoccerRanker.ResultParser

  test "it returns 1 point for teams that tie" do
    {{team1name, team1points}, {team2name, team2points}} = ResultParser.points("Lions 3, Snakes 3")
    assert team1name == "Lions"
    assert team1points == 1
    assert team2name == "Snakes"
    assert team2points == 1
  end

  test "returns 3 points for a win, 0 for a loss" do
    {{team1name, team1points}, {team2name, team2points}} = ResultParser.points("Lions 2, Snakes 1")
    assert team1name == "Lions"
    assert team1points == 3
    assert team2name == "Snakes"
    assert team2points == 0
  end

  test "works independent of input order (losing team first)" do
    {{team1name, team1points}, {team2name, team2points}} = ResultParser.points("Lions 1, Snakes 2")
    assert team1name == "Lions"
    assert team1points == 0
    assert team2name == "Snakes"
    assert team2points == 3
  end

  test "it handles spaces in the team name" do
    {{team1name, _}, {_, _}} = ResultParser.points("Long Team Name 3, Snakes 3")
    assert team1name == "Long Team Name"
  end

  test "it returns error when score is not included in input" do
    {{team1name, team1points}, {team2name, team2points}} = ResultParser.points("Lions, Snakes")

    assert team1name == "Lions"
    assert team1points == :error
    assert team2name == "Snakes"
    assert team2points == :error
  end
end
