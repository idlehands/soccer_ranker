defmodule SoccerRanker.ResultParser do
  require Logger

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

  defp assign_points({first_team, first_score}, {second_team, second_score}) when is_atom(first_score) or is_atom(second_score) do
    {{first_team, first_score},{second_team, second_score}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score}) when first_score == second_score do
    {{first_team, 1}, {second_team, 1}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score}) when first_score > second_score do
    {{first_team, 3}, {second_team, 0}}
  end
  defp assign_points({first_team, first_score}, {second_team, second_score}) when first_score < second_score do
    {{first_team, 0}, {second_team, 3}}
  end
  defp assign_points(bad_args) do
    Logger.error("Invalid data passed into assign points: #{inspect(bad_args)}")
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
