import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import util.{abs, from, gcd, last, read_file}

pub type Bus {
  Bus(route_length: Int)
}

pub type Schedule {
  Schedule(self_timestamp: Int, buses: List(Bus))
}

pub fn parse() -> Schedule {
  assert [timestamp, bus_list] = read_file("./data/day13.txt")
  let self_timestamp =
    timestamp
    |> string.trim
    |> int.parse
    |> result.unwrap(-1)

  let buses =
    bus_list
    |> string.trim
    |> string.split(",")
    |> list.filter_map(fn(entry) {
      case entry {
        "x" -> Ok(Bus(route_length: 0))
        n ->
          n
          |> int.parse
          |> result.map(fn(id) { Bus(route_length: id) })
      }
    })

  Schedule(self_timestamp: self_timestamp, buses: buses)
}

pub fn part_one() -> Int {
  let schedule = parse()

  let next_timestamp =
    from(schedule.self_timestamp)
    |> iterator.find(fn(timestamp) {
      schedule.buses
      |> list.filter(fn(b: Bus) { b.route_length != 0 })
      |> list.any(fn(b: Bus) { timestamp % b.route_length == 0 })
    })
    |> result.unwrap(-1)

  let bus =
    schedule.buses
    |> list.filter(fn(b: Bus) { b.route_length != 0 })
    |> list.find(fn(b: Bus) { next_timestamp % b.route_length == 0 })
    |> result.unwrap(Bus(route_length: -1))

  { next_timestamp - schedule.self_timestamp } * bus.route_length
}

pub fn find_timestamp(
  in: List(tuple(Int, Int)),
  current: Int,
  total: Int,
) -> Int {
  case in {
    [] -> total
    [_] -> total
    [tuple(offset, id), ..rest] ->
      case current % id == offset {
        True -> find_timestamp(rest, current, total * id)
        False -> find_timestamp(in, current + total, total)
      }
  }
}

pub fn test_schedule() -> Schedule {
  Schedule(
    self_timestamp: 0,
    buses: [
      Bus(route_length: 17),
      Bus(route_length: 0),
      Bus(route_length: 13),
      Bus(route_length: 19),
    ],
  )
}

pub fn part_two() -> Int {
  //let schedule = parse()
  let schedule = test_schedule()

  assert [first, ..rest] =
    schedule.buses
    |> list.index_map(fn(index, bus: Bus) { tuple(index, bus.route_length) })
    |> list.filter(fn(p) { pair.second(p) != 0 })
    |> list.map(fn(p) {
      assert tuple(index, id) = p
      tuple(id - index, id)
    })

  find_timestamp(rest, pair.first(first), pair.second(first))
}
