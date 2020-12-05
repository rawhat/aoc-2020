import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/pair
import gleam/regex
import gleam/result
import gleam/set
import gleam/string

import util.{file_stream, to_list}

pub const num_rows = 128
pub const num_seats = 8

pub fn get_seats() -> List(String) {
  "./data/day5.txt"
  |> file_stream
  |> to_list
}

pub fn find_index(
  pass pass: String,
  start_index start_index: Int,
  length length: Int,
  max max: Int,
  last last: String,
  down down: String,
  up up: String
) -> Int {
  pass
  |> string.slice(at_index: start_index, length: length)
  |> string.to_graphemes
  |> list.fold(tuple(0, max - 1), fn(char, curr) {
    let tuple(lower, upper) = curr
    let move = { upper - lower } / 2
    case char {
      c if c == down -> tuple(lower, upper - move - 1)
      c if c == up -> tuple(lower + move + 1, upper)
    }
  })
  |> fn(p) {
    let tuple(front, back) = p
    case last {
      c if c == down -> front
      c if c == up -> back
    }
  }
}

pub fn get_seat_id(pass: String) -> Int {
  let row = find_index(
    pass: pass,
    start_index: 0,
    length: 6,
    max: num_rows,
    last: string.slice(from: pass, at_index: 6, length: 1),
    down: "F",
    up: "B"
  )

  let seat = find_index(
    pass: pass,
    start_index: 7,
    length: 3,
    max: num_seats,
    last: string.slice(from: pass, at_index: 9, length: 1),
    down: "L",
    up: "R"
  )

  row * 8 + seat
}

pub fn test_get_seat_id() -> Bool {
  assert [567, 119, 820] =
    ["BFFFBBFRRR", "FFFBBBFRRR", "BBFFBBFRLL"]
    |> list.map(get_seat_id)

  True
}

pub fn get_seat_indices() -> List(Int) {
  get_seats()
  |> list.map(get_seat_id)
}

pub fn part_one() -> Int {
  get_seat_indices()
  |> list.sort(by: int.compare)
  |> list.reverse
  |> list.at(0)
  |> result.unwrap(-1)
}

pub fn part_two() -> Int {
  let seats =
    get_seat_indices()
    |> set.from_list

  let all_seats =
    iterator.range(from: 0, to: num_rows)
    |> iterator.flat_map(fn(row) {
      iterator.range(from: 0, to: num_seats)
      |> iterator.map(fn(seat) {
        row * 8 + seat
      })
    })
    |> iterator.to_list
    |> set.from_list

  all_seats
  |> set.filter(fn(seat) { set.contains(seats, seat) == False })
  |> set.to_list
  |> list.find(fn(seat) {
    set.contains(seats, seat - 1) && set.contains(seats, seat + 1)
  })
  |> result.unwrap(-1)
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
