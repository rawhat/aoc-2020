import gleam/iterator
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
