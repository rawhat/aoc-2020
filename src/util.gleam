pub external fn file_to_string(file: String) -> String =
  "Elixir.File" "read!"

pub external fn file_stream(file: String) -> List(String) =
  "Elixir.File" "stream!"

pub external fn to_list(list: List(a)) -> List(a) =
  "Elixir.Enum" "to_list"
