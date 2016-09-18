defmodule SoccerRankerTest.CollectorTest do
  use ExUnit.Case
  alias SoccerRanker.Collector

  test "aggregates passed in points, orders results by points" do
    Collector.start_link
    Collector.add_points({{"Snakes", 1},{"Badgers", 1}})
    Collector.add_points({{"Snakes", 3},{"Badgers", 0}})

    results = Collector.report

    assert results == [{"Snakes", 4}, {"Badgers", 1}]
  end
end
