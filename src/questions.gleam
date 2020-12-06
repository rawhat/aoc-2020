import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

import util.{file_to_string}

pub fn read_questions(matcher: fn(String) -> Int) -> Int {
  "./data/day6.txt"
  |> file_to_string
  |> string.split(on: "\n\n")
  |> list.map(matcher)
  |> list.fold(0, fn(m, n) { m + n })
}

pub fn any_yes(group: String) -> Int {
  group
  |> string.split(on: "\n")
  |> list.map(string.to_graphemes)
  |> list.flatten
  |> set.from_list
  |> set.to_list
  |> list.length
}

pub fn all_yes(group: String) -> Int {
  let [first, ..rest] =
    group
    |> string.split(on: "\n")
    |> list.map(string.to_graphemes)
    |> list.map(set.from_list)
    |> list.filter(fn(s) { set.size(s) != 0 })

  rest
  |> list.fold(first, fn(s, acc) { set.intersection(s, acc) })
  |> set.size
}

pub fn test() {
  let example = "abc

a
b
c

ab
ac

a
a
a
a

b"
  let one =
    example
    |> string.split(on: "\n\n")
    |> list.map(any_yes)
    |> list.fold(0, fn(m, n) { m + n })

  let two =
    example
    |> string.split(on: "\n\n")
    |> list.map(all_yes)
    |> list.fold(0, fn(m, n) { m + n })

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}

pub fn part_one() -> Int {
  any_yes
  |> read_questions
}

pub fn part_two() -> Int {
  all_yes
  |> read_questions
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
