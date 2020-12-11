defmodule Advent.Jolts do
  def get_selected_joltages() do
    :jolts.get_joltages()
    |> :jolts.get_selected_joltages()
  end

  def process([elem]) do
    [elem]
  end

  def process([curr | rest]) do
    {reachable, not_reachable} =
      rest
      |> Enum.split_with(&(&1 - curr <= 3))

    next_lists = process(not_reachable)

    reachable
    |> Enum.map(&[curr, &1])
    |> Enum.flat_map(fn [curr, next] ->
      next_lists
      |> Enum.map(&[curr, next | &1])
    end)
  end

  def part_two() do
    get_selected_joltages()
    |> process()
    |> Enum.count()
  end
end
