defmodule SoccerRanker.Collector do
  use GenServer
  require Logger

  defmodule Results do
    defstruct team_scores: %{}, teams_with_errors: []
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %Results{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def add_points(points) do
    GenServer.call(__MODULE__, {:add_points, points}, 100_000_000)
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

  defp aggregate_points(state, {team_name, :error}) do
    %{state | teams_with_errors: Enum.uniq([team_name | state.teams_with_errors])}
  end
  defp aggregate_points(state, {team_name, new_points}) do
    existing_points = state.team_scores[team_name] || 0
    new_total = existing_points + new_points
    %{state | team_scores: Map.put(state.team_scores, team_name, new_total)}
  end

  defp ordered_results(state) do
    Map.to_list(state.team_scores)
    |> Enum.sort(&score_sort(&1, &2))
  end

  defp score_sort({_team1name, team1points}, {_team2name, team2points}) when team1points != team2points do
    team1points > team2points
  end
  defp score_sort({team1name, team1points}, {team2name, team2points}) when team1points == team2points do
    team1name < team2name
  end

  defp ranked_with_errors(results) do
    ranked_results = calculate_rank(results.ordered_teams)
    ranked_strings = Enum.map(ranked_results, fn({rank, team_name, points}) ->
      "#{rank}. #{team_name}, #{print_points(points)}"
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
    {team, score} = List.first(unranked)
    ranked = [{1, team, score}]
    unranked = List.delete_at(unranked, 0)
    calculate_rank(ranked, unranked)
  end
  defp calculate_rank(ranked, []) do
    ranked
  end
  defp calculate_rank(ranked, unranked) do
    {previous_rank, _previous_name, previous_score} = List.last(ranked)
    {new_name, new_score} = List.first(unranked)
    new_rank = if previous_score == new_score do
      previous_rank
    else
      previous_rank + rank_count(ranked)
    end
    ranked = ranked ++ [{new_rank, new_name, new_score}]
    unranked = List.delete_at(unranked, 0)
    calculate_rank(ranked, unranked)
  end

  defp rank_count([], _rank, count) do
    count
  end
  defp rank_count(ranked, rank, count) do
    {previous_rank, _previous_name, _previous_score} = List.last(ranked)
    case previous_rank == rank do
      true ->
        ranked = List.delete_at(ranked, -1)
        rank_count(ranked, previous_rank, count + 1)
      false ->
        count
    end
  end
  defp rank_count(ranked) when is_list(ranked) do
    {previous_rank, _previous_name, _previous_score} = List.last(ranked)
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
