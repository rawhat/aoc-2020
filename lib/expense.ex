defmodule Advent.Expense do
  def parse do
    Path.join("./data", "day1.txt")
    |> Path.expand()
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(&Integer.parse/1)
    |> Stream.map(&elem(&1, 0))
    |> Enum.sort()
  end

  def get_pairs(expenses) do
    expenses
    |> Stream.flat_map(fn expense ->
      expenses
      |> Stream.filter(&(expense > &1))
      |> Stream.map(&{expense, &1})
    end)
  end

  def get_triples(expenses) do
    expenses
    |> get_pairs()
    |> Stream.flat_map(fn {left, right} ->
      expenses
      |> Stream.filter(&(&1 > right))
      |> Stream.map(&{left, right, &1})
    end)
  end

  def find_match(groups) do
    groups
    |> Enum.find({0}, fn group ->
      sum =
        group
        |> Tuple.to_list()
        |> Enum.sum()

      sum == 2020
    end)
  end

  def product(group) do
    group
    |> Tuple.to_list()
    |> Enum.reduce(1, &(&1 * &2))
  end

  def process() do
    expenses = parse()

    part_one =
      expenses
      |> get_pairs()
      |> find_match()
      |> product()

    part_two =
      expenses
      |> get_triples()
      |> find_match()
      |> product()

    IO.puts("Part one: #{part_one}")
    IO.puts("Part two: #{part_two}")
  end
end
