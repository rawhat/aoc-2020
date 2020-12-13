import gleam/iterator.{Done, Iterator, Next}
import gleam/list
import gleam/pair

pub external fn file_to_string(file: String) -> String =
  "Elixir.File" "read!"

pub external fn file_stream(file: String) -> List(String) =
  "Elixir.File" "stream!"

pub external fn to_list(list: List(a)) -> List(a) =
  "Elixir.Enum" "to_list"

pub external fn time(function: fn() -> a) -> tuple(Float, a) =
  "timer" "tc"

pub external fn abs(value: Int) -> Int =
  "Elixir.Kernel" "abs"

pub external fn sin(value: Float) -> Float =
  "math" "sin"

pub external fn cos(value: Float) -> Float =
  "math" "cos"

pub external fn gcd(a: Int, b: Int) -> Int =
  "Elixir.Integer" "gcd"

pub fn read_file(file: String) -> List(String) {
  file
  |> file_stream
  |> to_list
}

pub fn bench(function: fn() -> a) -> Float {
  function
  |> time
  |> pair.first
  |> fn(t) { t /. 1_000_000.0 }
}

pub fn slice(
  with collection: List(a),
  of length: Int,
  from index: Int,
) -> List(a) {
  collection
  |> iterator.from_list
  |> iterator.drop(index)
  |> iterator.take(length)
}

pub fn last(of collection: List(a)) -> Result(a, Nil) {
  let size = list.length(collection)

  collection
  |> list.drop(size - 1)
  |> list.at(0)
}

pub fn from(start start: Int) -> Iterator(Int) {
  iterator.unfold(
    from: start,
    with: fn(next) { Next(element: next, accumulator: next + 1) },
  )
}

pub fn take_while(
  from from: Iterator(a),
  where check: fn(a) -> Bool,
) -> Iterator(a) {
  iterator.unfold(
    from: iterator.step(from),
    with: fn(next) {
      case next {
        Done -> Done
        Next(element: element, accumulator: rest) ->
          case check(element) {
            True -> Next(element: element, accumulator: iterator.step(rest))
            False -> Done
          }
      }
    },
  )
}

pub fn sum(of numbers: List(Int)) -> Int {
  list.fold(numbers, 0, fn(m, n) { m + n })
}

// Same precision as erl `:math.pi`
const pi = 3.141592653589793

pub fn degrees_to_radians(degrees: Float) -> Float {
  2.0 *. pi *. degrees /. 360.0
}
