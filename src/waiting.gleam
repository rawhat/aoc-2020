import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/string
import util.{from, last, read_file, take_while}

pub type Position {
  Position(x: Int, y: Int)
}

pub fn move(from position: Position, x x: Int, y y: Int) -> Position {
  Position(x: position.x + x, y: position.y + y)
}

pub fn move_x(position: Position, x: Int) -> Position {
  move(position, x, 0)
}

pub fn move_y(position: Position, y: Int) -> Position {
  move(position, 0, y)
}

pub type GridItem {
  Empty
  Floor
  Occupied
}

pub fn grid_to_string(grid: Map(Position, GridItem)) -> String {
  from(start: 0)
  |> iterator.map(fn(row) {
    from(start: 0)
    |> iterator.map(fn(col) {
      grid
      |> map.get(Position(x: col, y: row))
    })
    |> take_while(result.is_ok)
    |> iterator.map(fn(res) {
      assert Ok(item) = res
      case item {
        Empty -> "L"
        Floor -> "."
        Occupied -> "#"
      }
    })
    |> iterator.to_list
    |> string.join("")
  })
  |> take_while(fn(s) { s != "" })
  |> iterator.to_list
  |> string.join("\n")
}

pub fn parse_input(input: List(String)) -> Map(Position, GridItem) {
  input
  |> list.index_map(fn(row_index, row) {
    row
    |> string.trim
    |> string.to_graphemes
    |> list.index_map(fn(col_index, item) {
      assert position = Position(x: col_index, y: row_index)
      let grid_item = case item {
        "L" -> Empty
        "#" -> Occupied
        "." -> Floor
      }
      tuple(position, grid_item)
    })
  })
  |> list.flatten
  |> map.from_list
}

pub fn input_from_test() -> Map(Position, GridItem) {
  "L.LL.LL.LL
LLLLLLL.LL
L.L.L..L..
LLLL.LL.LL
L.LL.LL.LL
L.LLLLL.LL
..L.L.....
LLLLLLLLLL
L.LLLLLL.L
L.LLLLL.LL"
  |> string.split("\n")
  |> parse_input
}

pub fn input_from_file() -> Map(Position, GridItem) {
  "./data/day11.txt"
  |> read_file
  |> parse_input
}

pub fn adjacent_counts(
  grid: Map(Position, GridItem),
  position: Position,
) -> Map(GridItem, Int) {
  [
    move_x(position, 1),
    move_x(position, -1),
    move_y(position, 1),
    move_y(position, -1),
    move(position, 1, 1),
    move(position, 1, -1),
    move(position, -1, 1),
    move(position, -1, -1),
  ]
  |> list.filter_map(map.get(grid, _))
  |> list.filter(fn(item) { item != Floor })
  |> list.fold(
    map.new(),
    fn(item, counts) {
      map.update(
        counts,
        item,
        fn(res) {
          res
          |> result.map(fn(count) { count + 1 })
          |> result.unwrap(1)
        },
      )
    },
  )
}

pub fn update_item(
  grid: Map(Position, GridItem),
  position: Position,
  item: GridItem,
  finder: fn(Map(Position, GridItem), Position) -> Map(GridItem, Int),
  limit: Int,
) -> Result(GridItem, Nil) {
  let adjacent = finder(grid, position)
  case item {
    Empty ->
      case map.keys(adjacent) {
        [Empty] -> Ok(Occupied)
        _ -> Error(Nil)
      }
    Occupied ->
      case map.get(adjacent, Occupied) {
        Ok(n) if n >= limit -> Ok(Empty)
        _ -> Error(Nil)
      }

    Floor -> Error(Nil)
  }
}

pub fn step(
  grid: Map(Position, GridItem),
  finder: fn(Map(Position, GridItem), Position) -> Map(GridItem, Int),
  limit: Int,
) -> List(tuple(Position, GridItem)) {
  grid
  |> map.to_list
  |> list.filter_map(fn(grid_item) {
    assert tuple(position, item) = grid_item
    case update_item(grid, position, item, finder, limit) {
      Ok(new_item) -> Ok(tuple(position, new_item))
      _ -> Error(Nil)
    }
  })
}

pub fn get_occupied_seats(
  grid: Map(Position, GridItem),
  finder finder: fn(Map(Position, GridItem), Position) -> Map(GridItem, Int),
  limit limit: Int,
) -> Int {
  grid
  |> iterator.unfold(
    with: fn(grid) {
      case step(grid, finder, limit) {
        [] -> Done
        changes ->
          changes
          |> map.from_list
          |> map.merge(grid, _)
          |> fn(acc) { Next(element: acc, accumulator: acc) }
      }
    },
  )
  |> iterator.to_list
  |> last
  |> result.unwrap(map.new())
  |> map.values
  |> list.filter(fn(item) { item == Occupied })
  |> list.length
}

pub fn part_one() -> Int {
  input_from_file()
  |> get_occupied_seats(finder: adjacent_counts, limit: 4)
}

pub type Direction {
  North
  East
  South
  West
  NorthEast
  SouthEast
  SouthWest
  NorthWest
}

pub fn get_updater(direction: Direction) -> fn(Position) -> Position {
  case direction {
    North -> fn(pos) { move_y(pos, 1) }
    East -> fn(pos) { move_x(pos, 1) }
    South -> fn(pos) { move_y(pos, -1) }
    West -> fn(pos) { move_x(pos, -1) }
    NorthEast -> fn(pos) { move(pos, 1, -1) }
    SouthEast -> fn(pos) { move(pos, 1, 1) }
    SouthWest -> fn(pos) { move(pos, -1, 1) }
    NorthWest -> fn(pos) { move(pos, -1, -1) }
  }
}

pub fn next_in_direction(
  grid: Map(Position, GridItem),
  position: Position,
  direction: Direction,
) -> GridItem {
  let updater = get_updater(direction)
  let next_position = updater(position)
  case map.get(grid, next_position) {
    Ok(Occupied) -> Occupied
    Ok(Empty) -> Empty
    Ok(Floor) -> next_in_direction(grid, next_position, direction)
    Error(_) -> Empty
  }
}

pub fn get_adjacencies(
  grid: Map(Position, GridItem),
  position: Position,
) -> Map(GridItem, Int) {
  [North, East, South, West, NorthEast, SouthEast, SouthWest, NorthWest]
  |> list.map(next_in_direction(grid, position, _))
  |> list.fold(
    map.new(),
    fn(pos, acc) {
      map.update(
        acc,
        pos,
        fn(res) {
          res
          |> result.map(fn(count) { count + 1 })
          |> result.unwrap(1)
        },
      )
    },
  )
}

pub fn part_two() -> Int {
  input_from_file()
  |> get_occupied_seats(finder: get_adjacencies, limit: 5)
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
