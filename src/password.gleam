import gleam/int
import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/option
import gleam/regex.{Match}
import gleam/result
import gleam/string
import util.{file_stream, to_list}

pub type PasswordRule {
  PasswordRule(character: String, min: Int, max: Int)
}

pub type PasswordEntry {
  PasswordEntry(rule: PasswordRule, password: String)
}

pub fn validate_entry(entry: PasswordEntry) -> Bool {
  let character_counts: Map(String, Int) = map.new()

  let rule_character_count =
    entry.password
    |> string.to_graphemes
    |> list.fold(
      character_counts,
      fn(char, map) {
        map.update(
          map,
          char,
          fn(e) {
            case e {
              Ok(count) -> count + 1
              _ -> 1
            }
          },
        )
      },
    )
    |> map.get(entry.rule.character)
    |> result.unwrap(0)

  rule_character_count >= entry.rule.min && rule_character_count <= entry.rule.max
}

pub fn char_at(password: String, index: Int) -> String {
  string.slice(from: password, at_index: index, length: 1)
}

pub fn validate_positions(entry: PasswordEntry) -> Bool {
  let is_position_one =
    char_at(entry.password, entry.rule.min - 1) == entry.rule.character
  let is_position_two =
    char_at(entry.password, entry.rule.max - 1) == entry.rule.character

  case tuple(is_position_one, is_position_two) {
    tuple(True, True) -> False
    tuple(False, False) -> False
    _ -> True
  }
}

pub const regex_string = "(\\d\\d?)-(\\d\\d?)\\s([a-z]):\\s([a-z]+)\\n"

pub fn count_valid_passwords() {
  let Ok(rule_regex) = regex.from_string(regex_string)

  let entries =
    "./data/day2.txt"
    |> file_stream
    |> to_list
    |> list.map(regex.scan(with: rule_regex, content: _))
    |> list.map(fn(matches: List(Match)) -> PasswordEntry {
      let [match] = matches
      let [min, max, character, password] = match.submatches

      let rule =
        PasswordRule(
          character: option.unwrap(character, ""),
          min: min
          |> option.unwrap("")
          |> int.parse
          |> result.unwrap(0),
          max: max
          |> option.unwrap("")
          |> int.parse
          |> result.unwrap(0),
        )

      PasswordEntry(rule: rule, password: option.unwrap(password, ""))
    })

  let part_one =
    entries
    |> list.filter(validate_entry)
    |> list.length

  let part_two =
    entries
    |> list.filter(validate_positions)
    |> list.length

  io.println(string.concat(["Part one: ", int.to_string(part_one)]))
  io.println(string.concat(["Part two: ", int.to_string(part_two)]))
}
