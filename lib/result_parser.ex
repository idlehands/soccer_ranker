defmodule SoccerRanker.ResultParser do
  require Logger

  defmodule ParseResult do
    defstruct name: nil, points: 0, goal_difference: 0
  end

  def points(score) when is_bitstring(score) do
    split_scores = String.split(score, ", ")
    first_team_info = List.first(split_scores) |> parse_team_score
    second_team_info = List.last(split_scores) |> parse_team_score
    assign_points(first_team_info, second_team_info)
  end

  defp parse_team_score(score_string) when is_bitstring(score_string) do
    split_score = String.split(score_string, " ")
    {team_name, score} = case List.last(split_score) |> score_from_string do
      :error ->
        {score_string, :error}
      score ->
        team_name = split_score |> List.delete_at(-1) |> Enum.join(" ")
        {team_name, score}
    end
    {team_name, score}
  end

  defp assign_points({first_team, first_score}, {second_team, second_score})
  when is_atom(first_score) or is_atom(second_score) do
    {%ParseResult{name: first_team, points: :error, goal_difference: 0},
     %ParseResult{name: second_team, points: :error, goal_difference: 0}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score})
  when first_score == second_score do
    {%ParseResult{name: first_team, points: 1, goal_difference: 0},
     %ParseResult{name: second_team, points: 1, goal_difference: 0}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score})
  when first_score > second_score do
    goal_difference = first_score - second_score
    {%ParseResult{name: first_team, points: 3, goal_difference: goal_difference},
     %ParseResult{name: second_team, points: 0, goal_difference: -1 * goal_difference}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score})
  when first_score < second_score do
    goal_difference = first_score - second_score
    {%ParseResult{name: first_team, points: 0, goal_difference:  goal_difference},
     %ParseResult{name: second_team, points: 3, goal_difference: -1 * goal_difference}}
  end

  defp score_from_string(score) do
    case Integer.parse(score) do
      {score, _} ->
        score
      :error ->
        :error
    end
  end
end
