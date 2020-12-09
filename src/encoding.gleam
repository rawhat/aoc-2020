import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import util.{last, read_file, slice}

pub fn read_from_file() -> List(Int) {
  "./data/day9.txt"
  |> read_file
  |> list.map(string.trim)
  |> list.filter_map(int.parse)
}

pub fn read_from_test() -> List(Int) {
  "35
20
15
25
47
40
62
55
65
95
102
117
150
182
127
219
299
277
309
576"
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter_map(int.parse)
}

pub fn part_one(preamble preamble: Int) -> Int {
  let output = read_from_file()

  iterator.range(from: 0, to: list.length(output) - preamble)
  |> iterator.filter(fn(start_index) {
    let tuple(preamble, [value]) =
      output
      |> list.drop(start_index)
      |> list.take(preamble + 1)
      |> list.split(at: preamble)

    let preamble_set = set.from_list(preamble)

    let found =
      preamble
      |> list.any(fn(left) { set.contains(preamble_set, value - left) })

    found == False
  })
  |> iterator.take(1)
  |> list.filter_map(fn(index) { list.at(output, index + preamble) })
  |> list.at(0)
  |> result.unwrap(-1)
}

pub fn find_range(output: List(Int), target: Int) -> List(Int) {
  tuple(0, 1)
  |> iterator.unfold(with: fn(range) {
    let tuple(lower, upper) = range

    let sublist = slice(with: output, of: upper - lower, from: lower)
    let sum = list.fold(sublist, 0, fn(m, n) { m + n })

    case sum == target {
      True -> Done
      False if sum < target ->
        Next(element: sublist, accumulator: tuple(lower, upper + 1))
      False if sum > target ->
        Next(element: sublist, accumulator: tuple(lower + 1, upper))
    }
  })
  |> iterator.to_list
  |> last
  |> result.unwrap([])
}

pub fn part_two() -> Int {
  let output = read_from_file()
  let target = part_one(preamble: 25)

  let range =
    output
    |> find_range(target)
    |> list.sort(by: int.compare)

  let start =
    range
    |> list.at(0)
    |> result.unwrap(0)

  let end =
    range
    |> last
    |> result.unwrap(0)

  start + end
}

pub fn solve() {
  let one = part_one(preamble: 25)
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
