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
