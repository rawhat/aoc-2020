import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/pair
import gleam/regex.{Match}
import gleam/set
import gleam/string

import util.{file_stream, to_list}

pub type Bag {
  Bag(
    color: String,
    contains: List(tuple(Int, String))
  )
}

pub fn read_from_file() -> Map(String, Bag) {
  "./data/day7.txt"
  |> file_stream
  |> to_list
  |> read_rules
}

pub fn read_from_test() -> Map(String, Bag) {
  "light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags."
  |> string.split("\n")
  |> read_rules
}

pub fn read_rules(data: List(String)) -> Map(String, Bag) {
  let Ok(bag_regex) = regex.from_string("^(\\w+ \\w+) bags contain")
  let Ok(container_regex) = regex.from_string("(\\d+)\\s(\\w+ \\w+) bags?,?")

  data
  |> list.map(fn(rule) {
    let [Match(submatches: [Some(color)], ..)] =
      regex.scan(with: bag_regex, content: rule)
    case regex.scan(with: container_regex, content: rule) {
      [] -> Bag(color: color, contains: [])
      matches -> {
        let contains =
          matches
          |> list.map(fn(match) {
            let Match(submatches: [Some(count), Some(color)], ..) = match
            let Ok(count) = int.parse(count)
            tuple(count, color)
          })
        Bag(color: color, contains: contains)
      }
    }
  })
  |> list.fold(map.new(), fn(bag: Bag, bags: Map(String, Bag)) -> Map(String, Bag) {
    map.insert(bags, bag.color, bag)
  })
}

pub fn part_one() -> Int {
  let bags = read_from_file()
  let color_to_match = "shiny gold"

  bags
  |> map.keys
  |> list.filter(fn(color) { color != color_to_match })
  |> iterator.from_list
  |> iterator.filter(fn(color) {
    let Ok(initial_bag) = map.get(bags, color)
    iterator.unfold(from: [initial_bag], with: fn(next_bags) {
      case next_bags {
        [] -> Done
        next_bags -> {
          let contains =
            next_bags
            |> list.map(fn(bag: Bag) -> List(Bag) {
              bag.contains
              |> list.filter_map(fn(p) { map.get(bags, pair.second(p)) })
            })
            |> list.flatten
          Next(element: next_bags, accumulator: contains)
        }
      }
    })
    |> iterator.to_list
    |> list.flatten
    |> list.any(fn(bag: Bag) -> Bool { bag.color == color_to_match })
  })
  |> iterator.to_list
  |> list.length
}

pub fn number_of_bags_inside(bags: Map(String, Bag), color: String) -> Int {
  let Ok(bag) = map.get(bags, color)
  case bag.contains {
    [] -> 0
    contains -> {
      contains
      |> list.fold(0, fn(p, total) {
        let tuple(count, other_color) = p
        total + count + { count * number_of_bags_inside(bags, other_color) }
      })
    }
  }
}

pub fn part_two() -> Int {
  let bags = read_from_file()
  let outer_color = "shiny gold"

  number_of_bags_inside(bags, outer_color)
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
