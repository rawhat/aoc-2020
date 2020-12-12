import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import util.{abs, cos, degrees_to_radians, read_file, sin}

pub type Movement {
  North
  South
  East
  West
  Left
  Right
  Forward
}

pub type Position {
  Position(x: Int, y: Int)
}

pub fn move(position: Position, x: Int, y: Int) -> Position {
  Position(x: position.x + x, y: position.y + y)
}

pub fn move_x(position: Position, x: Int) -> Position {
  move(position, x, 0)
}

pub fn move_y(position: Position, y: Int) -> Position {
  move(position, 0, y)
}

pub fn move_pos(position: Position, offset: Position) -> Position {
  Position(
    x: position.x + offset.x,
    y: position.y + offset.y,
  )
}

pub type Ship {
  Ship(position: Position, rotation: Int)
}

pub fn new_ship() -> Ship {
  Ship(position: Position(x: 0, y: 0), rotation: 0)
}

pub fn get_movement(from: String) -> Movement {
  case from {
    "N" -> North
    "S" -> South
    "E" -> East
    "W" -> West
    "L" -> Left
    "R" -> Right
    "F" -> Forward
  }
}

pub type Instruction {
  Instruction(direction: Movement, value: Int)
}

pub fn parse_instruction(line: String) -> Instruction {
  assert [direction, ..value_string] = string.to_graphemes(line)
  Instruction(
    direction: get_movement(direction),
    value:
      value_string
      |> string.join("")
      |> string.trim
      |> int.parse
      |> result.unwrap(0),
  )
}

pub fn travel(instruction: Instruction, ship: Ship) -> Ship {
  case instruction {
    Instruction(direction: North, value: value) ->
      Ship(..ship, position: move_y(ship.position, value))
    Instruction(direction: South, value: value) ->
      Ship(..ship, position: move_y(ship.position, -1 * value))
    Instruction(direction: East, value: value) ->
      Ship(..ship, position: move_x(ship.position, value))
    Instruction(direction: West, value: value) ->
      Ship(..ship, position: move_x(ship.position, -1 * value))
    Instruction(direction: Left, value: value) ->
      Ship(..ship, rotation: ship.rotation + value)
    Instruction(direction: Right, value: value) ->
      Ship(..ship, rotation: ship.rotation - value)
    Instruction(direction: Forward, value: value) -> {
      let x =
        ship.rotation
        |> int.to_float
        |> degrees_to_radians
        |> cos
        |> float.round
        |> fn(rot) { rot * value }

      let y =
        ship.rotation
        |> int.to_float
        |> degrees_to_radians
        |> sin
        |> float.round
        |> fn(rot) { rot * value }

      Ship(..ship, position: move(ship.position, x, y))
    }
  }
}

pub fn read_from_file() -> List(Instruction) {
  "./data/day12.txt"
  |> read_file
  |> list.map(parse_instruction)
}

pub fn read_from_test() -> List(Instruction) {
  "F10
N3
F7
R90
F11"
  |> string.split("\n")
  |> list.map(parse_instruction)
}

pub fn part_one() -> Int {
  read_from_file()
  |> list.fold(new_ship(), travel)
  |> fn(ship: Ship) {
    abs(ship.position.x) + abs(ship.position.y)
  }
}

pub type ShipWithWaypoint {
  ShipWithWaypoint(
    ship: Position,
    waypoint: Position,
  )
}

pub fn new_ship_with_waypoint() -> ShipWithWaypoint {
  ShipWithWaypoint(
    ship: Position(x: 0, y: 0),
    waypoint: Position(x: 10, y: 1),
  )
}

pub fn get_waypoint_offset(with_waypoint: ShipWithWaypoint) -> Position {
  let x = with_waypoint.waypoint.x - with_waypoint.ship.x
  let y = with_waypoint.waypoint.y - with_waypoint.ship.y

  Position(x: x, y: y)
}

pub fn get_position_after_rotation(
  waypoint_offset: Position,
  rotation: Int
) -> Position {
  let _ = io.debug(waypoint_offset)
  case rotation {
    90 | -270 -> Position(x: -1 * waypoint_offset.y, y: waypoint_offset.x)
    -90 | 270 -> Position(x: waypoint_offset.y, y: -1 * waypoint_offset.x)
    180 | -180 -> Position(x: -1 * waypoint_offset.x, y: -1 * waypoint_offset.y)
  }
}

pub fn travel_with_waypoint(
  instruction: Instruction,
  with_waypoint: ShipWithWaypoint
) -> ShipWithWaypoint {
  case instruction {
    Instruction(direction: North, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint: move_y(with_waypoint.waypoint, value)
      )
    Instruction(direction: South, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint: move_y(with_waypoint.waypoint, -1 * value)
      )
    Instruction(direction: East, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint: move_x(with_waypoint.waypoint, value)
      )
    Instruction(direction: West, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint: move_x(with_waypoint.waypoint, -1 * value)
      )
    Instruction(direction: Left, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint:
          with_waypoint
          |> get_waypoint_offset
          |> get_position_after_rotation(value)
          |> move_pos(with_waypoint.ship, _)
      )
    Instruction(direction: Right, value: value) ->
      ShipWithWaypoint(
        ..with_waypoint,
        waypoint:
          with_waypoint
          |> get_waypoint_offset
          |> get_position_after_rotation(-1 * value)
          |> io.debug
          |> move_pos(with_waypoint.ship, _)
      )
    Instruction(direction: Forward, value: value) -> {
      let offset = get_waypoint_offset(with_waypoint)
      let new_ship = move(with_waypoint.ship, offset.x * value, offset.y * value)
      ShipWithWaypoint(
        ship: new_ship,
        waypoint: move_pos(new_ship, offset),
      )
    }
  }
}

pub fn part_two() -> Int {
  read_from_file()
  |> list.fold(new_ship_with_waypoint(), travel_with_waypoint)
  |> fn(with_waypoint: ShipWithWaypoint) {
    abs(with_waypoint.ship.x) + abs(with_waypoint.ship.y)
  }
}
