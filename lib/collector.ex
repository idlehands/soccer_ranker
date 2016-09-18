defmodule SoccerRanker.Collector do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def add_points(points) do
    GenServer.call(__MODULE__, {:add_points, points})
  end

  def report do
    GenServer.call(__MODULE__, :report, 100_000_000)
  end

  def handle_call({:add_points, points}, _from, state) do
    state = update_points(points, state)
    {:reply, :ok, state}
  end
  def handle_call(:report, _from, state) do
    results = ordered_results(state)
    {:reply, results, state}
  end

  def handle_cast(message, state) do
    Logger.error("unhandled message recieved: #{message}")
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.error("unhandled message recieved: #{message}")
    {:noreply, state}
  end

  defp update_points({team1data,team2data}, []) do
    update_points({team1data, team2data}, %{})
  end
  defp update_points({team1data, team2data}, state) when is_map(state) do
    state
    |> aggregate_points(team1data)
    |> aggregate_points(team2data)
  end

  defp aggregate_points(state, {team_name, new_points}) do
    existing_points = state[team_name] || 0
    new_total = existing_points + new_points
    Map.put(state, team_name, new_total)
  end

  defp ordered_results(state) do
    Map.to_list(state)
    |> Enum.sort(&score_sort(&1, &2))
  end

  def score_sort({_team1name, team1points}, {_team2name, team2points}) when team1points != team2points do
    team1points > team2points
  end
end

