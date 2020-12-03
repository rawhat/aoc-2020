import gleam/int
import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/string

import util.{file_stream, to_list}

pub type Position {
  Position(x: Int, y: Int)
}

pub fn move(x: Int, y: Int, x_bound: Int) -> fn(Position) -> Position {
  fn(position) {
    let Position(x: old_x, y: old_y) = position

    Position(
      x: { old_x + x } % x_bound,
      y: old_y + y
    )
  }
}

pub type Entry {
  Tree
  Empty
}

pub type Terrain {
  Terrain(map: Map(Position, Entry), x_bound: Int)
}

pub fn read_terrain() -> Terrain {
  let data =
    "./data/day3.txt"
    |> file_stream
    |> to_list

  let terrain_map =
    data
    |> list.index_map(fn(index, row) { tuple(index, string.trim(row)) })
    |> list.fold(map.new(), fn(r, m) {
      let tuple(row_index, row) = r
      row
      |> string.to_graphemes
      |> list.index_map(fn(index, character) {
        let position = Position(x: index, y: row_index)
        let entry =
          case character {
            "." -> Empty
            "#" -> Tree
          }

        tuple(position, entry)
      })
      |> list.fold(m, fn(p, m) {
        let tuple(position, entry) = p
        map.insert(m, position, entry)
      })
    })

  let x_bound =
    data
    |> list.at(0)
    |> result.unwrap("")
    |> string.length

  Terrain(map: terrain_map, x_bound: x_bound - 1)
}

pub fn rfind_trees(
  terrain: Terrain,
  position: Position,
  move: fn(Position) -> Position,
  count: Int
) -> Int {
  let next_position = move(position)
  case map.get(terrain.map, position) {
    Ok(Tree) -> rfind_trees(terrain, next_position, move, count + 1)
    Ok(Empty) -> rfind_trees(terrain, next_position, move, count)
    _ -> count
  }
}

pub fn find_trees(move_x: Int, move_y: Int) -> Int {
  let terrain = read_terrain()
  let mover = move(move_x, move_y, terrain.x_bound)
  rfind_trees(terrain, Position(x: 0, y: 0), mover, 0)
}

pub fn part_one() -> Int {
  find_trees(3, 1)
}

pub fn part_two() -> Int {
  [tuple(1, 1), tuple(3, 1), tuple(5, 1), tuple(7, 1), tuple(1, 2)]
  |> list.map(fn(p) {
    let tuple(x, y) = p
    find_trees(x, y)
  })
  |> list.fold(1, fn(m, n) { m * n })
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
