import gleam/int
import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/regex.{Match}
import gleam/result
import gleam/string
import util.{binary_to_int, read_file, sum}

pub type MaskElement {
  Digit(Int)
  Skip
}

pub type Operation {
  SetMask(value: List(MaskElement))
  SetMemory(location: Int, value: Int)
}

pub type Program {
  Program(
    instructions: List(Operation),
    mask: List(MaskElement),
    memory: Map(Int, Int),
  )
}

const mask_string = "^mask = ([01X]+)$"
const mem_string = "^mem\\[(\\d+)\\] = (\\d+)$"

pub fn extract_set_mask(str: String) -> Operation {
  str
  |> string.to_graphemes
  |> list.map(fn(c) {
    case c {
      "X" -> Skip
      n ->
        n
        |> int.parse
        |> result.unwrap(-1)
        |> Digit
    }
  })
  |> SetMask
}

pub fn extract_set_mem(dest: String, value: String) -> Operation {
  let location =
    dest
    |> int.parse
    |> result.unwrap(-1)

  value
  |> int.parse
  |> result.unwrap(-1)
  |> SetMemory(location: location, value: _)
}

pub fn read_program() -> Program {
  assert Ok(mask) = regex.from_string(mask_string)
  assert Ok(mem) = regex.from_string(mem_string)

  "./data/day14.txt"
  |> read_file
  |> list.map(string.trim)
  |> list.filter_map(fn(line) {
    case regex.scan(mask, line), regex.scan(mem, line) {
      [Match(submatches: [Some(m)], ..)], _ ->
        Ok(extract_set_mask(m))
      _, [Match(submatches: [Some(dest), Some(value)], ..)] ->
        Ok(extract_set_mem(dest, value))
      _, _ ->
        Error(Nil)
    }
  })
  |> fn(program) {
    assert [SetMask(value: value), ..rest_of_program] = program

    Program(
      instructions: rest_of_program,
      mask: value,
      memory: map.new(),
    )
  }
}

pub fn update_value_with_mask(value: Int, mask: List(MaskElement)) -> Int {
  value
  |> int.to_base_string(2)
  |> string.pad_left(to: list.length(mask), with: "0")
  |> string.to_graphemes
  |> list.zip(mask)
  |> list.map(fn(p) {
    case p {
      tuple(original, Skip) -> original
      tuple(_, Digit(n)) -> int.to_string(n)
    }
  })
  |> string.join("")
  |> binary_to_int(2)
}

pub fn set_memory(program: Program, location: Int, value: Int) -> Program {
  Program(..program, memory: map.insert(program.memory, location, value))
}

pub fn run_program(program: Program) -> Program {
  case program.instructions {
    [] ->
      program
    [SetMask(value: value), ..rest] ->
      Program(..program, mask: value, instructions: rest)
      |> run_program
    [SetMemory(location: location, value: value), ..rest] ->
      value
      |> update_value_with_mask(program.mask)
      |> set_memory(program, location, _)
      |> fn(p) { Program(..p, instructions: rest) }
      |> run_program
  }
}

pub fn part_one() -> Int {
  read_program()
  |> run_program
  |> fn(p: Program) { map.values(p.memory) }
  |> sum
}


pub fn test_value_with_mask() -> Nil {
  let value = 11
  let mask =
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X"
    |> extract_set_mask
    |> fn(s) {
      case s {
        SetMask(value: value) -> value
      }
    }

  let updated =
    value
    |> update_value_with_mask(mask)
    |> io.debug

  Nil
}
