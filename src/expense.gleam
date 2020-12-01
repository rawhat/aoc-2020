import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{None, Some, unwrap}
import gleam/result
import gleam/string

pub external fn file_stream(file: String) -> List(String) =
  "Elixir.File" "stream!"

pub external fn to_list(list: List(a)) -> List(a) =
  "Elixir.Enum" "to_list"

pub fn parse() -> List(Int) {
  "./data/day1.txt"
  |> file_stream
  |> to_list
  |> list.map(string.trim(_))
  |> list.filter_map(int.parse(_))
  |> list.filter(fn(n) { n < 2020 })
  |> list.sort(by: int.compare)
}

pub fn get_pairs(expenses: List(Int)) -> List(List(Int)) {
  expenses
  |> iterator.from_list
  |> iterator.flat_map(fn(n) {
    expenses
    |> iterator.from_list
    |> iterator.filter(fn(m) { m > n })
    |> iterator.map(fn(m) { [m, n] })
  })
  |> iterator.to_list
}

pub fn get_triples(expenses: List(Int)) -> List(List(Int)) {
  expenses
  |> get_pairs
  |> iterator.from_list
  |> iterator.flat_map(fn(p) {
    let [left, right] = p

    expenses
    |> iterator.from_list
    |> iterator.filter(fn(m) { m > right })
    |> iterator.map(fn(m) { [left, right, m] })
  })
  |> iterator.to_list
}

fn find_match(groups: List(List(Int))) -> Result(List(Int), Nil) {
  list.find(groups, fn(g) { list.fold(g, 0, fn(m, n) { m + n }) == 2020 })
}

fn get_product(group: Result(List(Int), Nil)) -> Int {
  group
  |> result.unwrap([0])
  |> list.fold(1, fn(p, n) { p * n })
}

pub fn process() {
  let expenses = parse()

  let part_one =
    expenses
    |> get_pairs
    |> find_match
    |> get_product

  let part_two =
    expenses
    |> get_triples
    |> find_match
    |> get_product

  io.println(string.concat(["Part one: ", int.to_string(part_one)]))
  io.println(string.concat(["Part two: ", int.to_string(part_two)]))
}
