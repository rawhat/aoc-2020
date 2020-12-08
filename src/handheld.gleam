import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/pair
import gleam/regex.{Match}
import gleam/result
import gleam/set.{Set}
import gleam/string
import util.{read_file}

pub const command_regex = "(acc|jmp|nop) (\\+|\\-)(\\d+)"

pub type Instruction {
  Accumulate(amount: Int)
  Jump(to: Int)
  NoOp(value: Int)
}

pub type Program {
  Program(
    accumulator: Int,
    history: Set(Int),
    instructions: Map(Int, Instruction),
    pointer: Int,
  )
}

pub fn generate_program(instructions: Map(Int, Instruction)) -> Program {
  Program(
    accumulator: 0,
    history: set.new(),
    instructions: instructions,
    pointer: 0,
  )
}

pub fn new_program() -> Program {
  map.new()
  |> generate_program
}

pub fn add_instruction(program: Program, instruction: Instruction) -> Program {
  let next_index = map.size(program.instructions)

  Program(
    ..program,
    instructions: map.insert(program.instructions, next_index, instruction),
  )
}

pub fn execute(program: Program) -> Program {
  program.instructions
  |> map.get(program.pointer)
  |> result.map(fn(instruction) {
    let with_history =
      Program(..program, history: set.insert(program.history, program.pointer))
    case instruction {
      Accumulate(amount: value) ->
        Program(
          ..with_history,
          accumulator: program.accumulator + value,
          pointer: program.pointer + 1,
        )
      Jump(to: offset) ->
        Program(..with_history, pointer: program.pointer + offset)
      NoOp(..) -> Program(..with_history, pointer: program.pointer + 1)
    }
  })
  |> result.unwrap(program)
}

pub fn read_from_file() -> List(String) {
  "./data/day8.txt"
  |> read_file
}

pub fn read_from_test() -> List(String) {
  "nop +0
acc +1
jmp +4
acc +3
jmp -3
acc -99
acc +1
jmp -4
acc +6"
  |> string.split(on: "\n")
}

pub fn read_program(input: List(String)) -> Program {
  let Ok(re) = regex.from_string(command_regex)

  input
  |> list.map(regex.scan(with: re, content: _))
  |> list.map(fn(match) {
    let [Match(submatches: [Some(cmd), Some(sign), Some(data)], ..)] = match
    let value =
      data
      |> int.parse
      |> result.unwrap(0)
      |> fn(d) {
        case sign {
          "+" -> d
          "-" -> -1 * d
        }
      }
    case cmd {
      "acc" -> Accumulate(amount: value)
      "jmp" -> Jump(to: value)
      "nop" -> NoOp(value: value)
    }
  })
  |> list.fold(
    new_program(),
    fn(instruction, program) { add_instruction(program, instruction) },
  )
}

pub fn run(program: Program) -> Result(Program, Program) {
  program
  |> iterator.unfold(
    with: fn(program: Program) {
      Next(element: program, accumulator: execute(program))
    },
  )
  |> iterator.map(fn(program: Program) -> Result(Result(Program, Program), Nil) {
    let repeated = set.contains(program.history, program.pointer)
    let terminated = program.pointer >= map.size(program.instructions)
    case repeated, terminated {
      True, _ -> Ok(Error(program))
      _, True -> Ok(Ok(program))
      _, _ -> Error(Nil)
    }
  })
  |> iterator.find(fn(res) { result.is_ok(res) })
  |> result.unwrap(Error(Nil))
  |> result.map_error(fn(_) { program })
  |> result.flatten
}

pub fn part_one() -> Int {
  let Error(final_program) =
    read_from_file()
    |> read_program
    |> run

  final_program.accumulator
}

pub fn part_two() -> Int {
  let input_program =
    read_from_file()
    |> read_program

  input_program.instructions
  |> fn(instructions) { iterator.range(from: 0, to: map.size(instructions)) }
  |> iterator.filter(fn(instruction) {
    case map.get(input_program.instructions, instruction) {
      Ok(Jump(..)) | Ok(NoOp(..)) -> True
      _ -> False
    }
  })
  |> iterator.map(fn(instruction) {
    let Ok(existing_instruction) =
      map.get(input_program.instructions, instruction)
    let new_instruction = case existing_instruction {
      Jump(to: value) -> NoOp(value: value)
      NoOp(value: value) -> Jump(to: value)
      instruction -> instruction
    }
    map.insert(input_program.instructions, instruction, new_instruction)
  })
  |> iterator.map(generate_program)
  |> iterator.map(run)
  |> iterator.find(result.is_ok)
  |> result.unwrap(Error(input_program))
  |> fn(res: Result(Program, Program)) {
    case res {
      Ok(program) -> program.accumulator
      Error(_) -> -1
    }
  }
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
