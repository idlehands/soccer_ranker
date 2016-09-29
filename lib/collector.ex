defmodule SoccerRanker.Collector do
  use GenServer
  require Logger

  defmodule Results do
    defstruct team_scores: %{}, teams_with_errors: []
  end

  defmodule TeamData do
    defstruct name: nil, points: 0, goal_difference: 0, rank: nil
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %Results{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def add_points(points) do
    GenServer.call(__MODULE__, {:add_points, points}, 1_000_000)
  end

  def report do
    GenServer.call(__MODULE__, :report)
  end

  def report_and_rank do
    report |> ranked_with_errors
  end

  def handle_call({:add_points, points}, _from, state) do
    state = update_points(points, state)
    {:reply, :ok, state}
  end
  def handle_call(:report, _from, state) do
    results = ordered_results(state)
    {:reply, %{ordered_teams: results, teams_with_errors: state.teams_with_errors}, state}
  end

  def handle_cast(message, state) do
    Logger.error("unhandled message recieved: #{message}")
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.error("unhandled message recieved: #{message}")
    {:noreply, state}
  end

  defp update_points({team1data, team2data}, state) do
    state
    |> aggregate_points(team1data)
    |> aggregate_points(team2data)
  end

  defp aggregate_points(state, %{points: :error} = team_data) do
    %{state | teams_with_errors: Enum.uniq([team_data.name | state.teams_with_errors])}
  end
  defp aggregate_points(state, team_data) when is_map(team_data) do
    existing_data = Map.get(state.team_scores, team_data.name, %TeamData{name: team_data.name})
    updated_points = existing_data.points + team_data.points
    updated_goal_difference = existing_data.goal_difference + team_data.goal_difference
    updated_team_data = %TeamData{name: team_data.name, points: updated_points, goal_difference: updated_goal_difference}
    %{state | team_scores: Map.put(state.team_scores, team_data.name, updated_team_data)}
  end

  defp ordered_results(state) do
    Map.to_list(state.team_scores)
    |> Enum.map(fn({_name, data}) -> data end)
    |> Enum.sort(&score_sort(&1,&2))
  end

  defp score_sort(%{points: points1}, %{points: points2})
  when points1 != points2 do
    points1 > points2
  end
  defp score_sort(%{goal_difference: gd1} = team1data, %{goal_difference: gd2} = team2data)
  when gd1 == gd2 do
    team1data.name < team2data.name
  end
  defp score_sort(team1data, team2data) do
    team1data.goal_difference > team2data.goal_difference
  end

  defp ranked_with_errors(results) do
    ranked_results = calculate_rank(results.ordered_teams)
    ranked_strings = Enum.map(ranked_results, fn(team_data) ->
      "#{team_data.rank}. #{team_data.name}, #{print_points(team_data.points)}, GD: #{team_data.goal_difference}"
    end)

    if Enum.count(results.teams_with_errors) > 0 do
      sorted_error_teams = Enum.sort(results.teams_with_errors)
      error_message = "Teams with errors: " <> Enum.join(sorted_error_teams, ", ")
      ranked_strings ++ [error_message]
    else
      ranked_strings
    end
  end

  defp calculate_rank(unranked) do
    team = List.first(unranked)
    ranked = [%{team | rank: 1}]
    unranked = List.delete_at(unranked, 0)
    calculate_rank(ranked, unranked)
  end
  defp calculate_rank(ranked, []) do
    ranked
  end
  defp calculate_rank(ranked, unranked) do
    ranked_team = List.last(ranked)
    unranked_team = List.first(unranked)
    new_rank = if unranked_team.points == ranked_team.points
    && unranked_team.goal_difference == ranked_team.goal_difference do
      ranked_team.rank
    else
      ranked_team.rank + rank_count(ranked)
    end
    ranked = ranked ++ [%{unranked_team | rank: new_rank}]
    unranked = List.delete_at(unranked, 0)
    calculate_rank(ranked, unranked)
  end

  defp rank_count([], _rank, count) do
    count
  end
  defp rank_count(ranked, rank, count) do
    %{rank: previous_rank} = List.last(ranked)
    case previous_rank == rank do
      true ->
        ranked = List.delete_at(ranked, -1)
        rank_count(ranked, previous_rank, count + 1)
      false ->
        count
    end
  end
  defp rank_count(ranked) when is_list(ranked) do
    %{rank: previous_rank} = List.last(ranked)
    ranked = List.delete_at(ranked, -1)
    rank_count(ranked, previous_rank, 1)
  end

  defp print_points(points) when points == 1 do
    "1 pt"
  end
  defp print_points(points) do
    "#{points} pts"
  end

end
