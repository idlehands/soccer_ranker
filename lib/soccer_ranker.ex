defmodule SoccerRanker do
  alias SoccerRanker.Collector
  alias SoccerRanker.ResultParser

  def main(args) do
    file_name = List.first(args)
    case File.open(file_name, [:read]) do
      {:ok, file_reader} ->
        Collector.start_link
        read_and_rank(file_reader)
        |> Enum.each(&IO.puts(&1))
      _anything_else ->
        IO.puts("Unable to open file at #{file_name}")
        :error
    end
  end

  defp read_and_rank(file_reader) do
    case IO.read(file_reader, :line) do
      :eof ->
        Collector.report_and_rank
      line ->
        String.strip(line)
        |> ResultParser.points
        |> Collector.add_points
        read_and_rank(file_reader)
    end
  end

end
