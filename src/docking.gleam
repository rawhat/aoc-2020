import gleam/int
import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/pair
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

pub fn read_from_file() -> Program {
  "./data/day14.txt"
  |> read_file
  |> list.map(string.trim)
  |> read_program
}

pub fn read_from_test() -> Program {
  "mask = 000000000000000000000000000000X1001X
mem[42] = 100
mask = 00000000000000000000000000000000X0XX
mem[26] = 1"
  |> string.split("\n")
  |> list.map(string.trim)
  |> read_program
}

pub fn read_program(input: List(String)) -> Program {
  assert Ok(mask) = regex.from_string(mask_string)
  assert Ok(mem) = regex.from_string(mem_string)

  input
  |> list.filter_map(fn(line) {
    case regex.scan(mask, line), regex.scan(mem, line) {
      [Match(submatches: [Some(m)], ..)], _ -> Ok(extract_set_mask(m))
      _, [Match(submatches: [Some(dest), Some(value)], ..)] ->
        Ok(extract_set_mem(dest, value))
      _, _ -> Error(Nil)
    }
  })
  |> fn(program) {
    assert [SetMask(value: value), ..rest_of_program] = program

    Program(instructions: rest_of_program, mask: value, memory: map.new())
  }
}

pub fn get_value_with_mask(
  value: Int,
  mask: List(MaskElement),
) -> List(tuple(Int, MaskElement)) {
  value
  |> int.to_base_string(2)
  |> string.pad_left(to: list.length(mask), with: "0")
  |> string.to_graphemes
  |> list.zip(mask)
  |> list.map(fn(p) {
    assert Ok(n) =
      pair.first(p)
      |> int.parse

    tuple(n, pair.second(p))
  })
}

pub fn binary_list_to_decimal(binary: List(Int)) -> Int {
  binary
  |> list.map(int.to_string)
  |> string.join("")
  |> binary_to_int(2)
}

pub fn update_value_with_mask(value: Int, mask: List(MaskElement)) -> Int {
  value
  |> get_value_with_mask(mask)
  |> list.map(fn(p) {
    case p {
      tuple(original, Skip) -> original
      tuple(_, Digit(n)) -> n
    }
  })
  |> binary_list_to_decimal
}

pub fn set_memory(program: Program, location: Int, value: Int) -> Program {
  Program(..program, memory: map.insert(program.memory, location, value))
}

pub fn run_program(program: Program) -> Program {
  case program.instructions {
    [] -> program
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
  read_from_file()
  |> run_program
  |> fn(p: Program) { map.values(p.memory) }
  |> sum
}

pub fn get_permutations(
  location: Int,
  mask: List(MaskElement),
) -> List(List(Int)) {
  location
  |> get_value_with_mask(mask)
  |> list.fold(
    [[]],
    fn(next, acc) {
      case next {
        tuple(_, Digit(1)) -> list.map(acc, fn(l) { [1, ..l] })
        tuple(n, Digit(0)) -> list.map(acc, fn(l) { [n, ..l] })
        tuple(_, Skip) ->
          acc
          |> list.map(fn(l) { list.map([0, 1], fn(n) { [n, ..l] }) })
          |> list.flatten
      }
    },
  )
  |> list.map(list.reverse)
}

pub fn run_with_combinations(program: Program) -> Program {
  case program.instructions {
    [] -> program
    [SetMask(value: value), ..rest] ->
      Program(..program, mask: value, instructions: rest)
      |> run_with_combinations
    [SetMemory(location: location, value: value), ..rest] ->
      location
      |> get_permutations(program.mask)
      |> list.map(binary_list_to_decimal)
      |> list.fold(program.memory, fn(loc, mem) { map.insert(mem, loc, value) })
      |> fn(mem) { Program(..program, memory: mem, instructions: rest) }
      |> run_with_combinations
  }
}

pub fn part_two() -> Int {
  read_from_file()
  |> run_with_combinations
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

pub fn test_permutations() -> Nil {
  let permutations =
    extract_set_mask("000000000000000000000000000000X1001X")
    |> fn(s: Operation) {
      case s {
        SetMask(value: value) -> value
      }
    }
    |> get_permutations(42, _)
    |> io.debug

  Nil
}

pub fn test_other_permutations() -> Nil {
  let permutations =
    extract_set_mask("00000000000000000000000000000000X0XX")
    |> fn(s: Operation) {
      case s {
        SetMask(value: value) -> value
      }
    }
    |> get_permutations(26, _)
    |> io.debug

  Nil
}

pub fn run_test_program() -> Int {
  read_from_test()
  |> run_with_combinations
  |> fn(p: Program) { map.values(p.memory) }
  |> sum
}
