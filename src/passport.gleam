import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/regex.{Match}
import gleam/result
import gleam/string
import util.{file_to_string}

pub fn read_passports() -> List(Map(String, String)) {
  "./data/day4.txt"
  |> file_to_string
  |> string.split("\n\n")
  |> iterator.from_list
  |> iterator.map(string.replace(_, each: "\n", with: " "))
  |> iterator.map(string.split(_, on: " "))
  |> iterator.map(fn(key_pairs) {
    key_pairs
    |> list.map(string.split(_, on: ":"))
    |> list.filter_map(fn(p) {
      case p {
        [key, value, ..] -> Ok(tuple(key, value))
        _ -> Error(Nil)
      }
    })
    |> map.from_list
  })
  |> iterator.to_list
}

pub const required_fields = ["byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid"]

pub fn validate_passport(passport: Map(String, String)) -> Bool {
  required_fields
  |> list.all(fn(field) {
    case map.get(passport, field) {
      Ok("") -> False
      Error(_) -> False
      _ -> True
    }
  })
}

pub fn get_field_validation(field: String) -> fn(String) -> Bool {
  case field {
    "byr" -> fn(byr) {
      case int.parse(byr) {
        Ok(n) if n >= 1920 && n <= 2002 -> True
        _ -> False
      }
    }
    "iyr" -> fn(iyr) {
      case int.parse(iyr) {
        Ok(n) if n >= 2010 && n <= 2020 -> True
        _ -> False
      }
    }
    "eyr" -> fn(eyr) {
      case int.parse(eyr) {
        Ok(n) if n >= 2020 && n <= 2030 -> True
        _ -> False
      }
    }
    "hgt" -> fn(hgt) {
      let Ok(hgt_regex) = regex.from_string("^(\\d+)(cm|in)$")
      case regex.scan(with: hgt_regex, content: hgt) {
        [Match(submatches: [Some(height), Some(unit)], ..)] ->
          case unit, int.parse(height) {
            "cm", Ok(n) if n >= 150 && n <= 193 -> True
            "in", Ok(n) if n >= 59 && n <= 76 -> True
            _, _ -> False
          }
        _ -> False
      }
    }
    "hcl" -> fn(hcl) {
      let Ok(hair_regex) = regex.from_string("^#[a-f0-9]{6}$")
      regex.check(with: hair_regex, content: hcl)
    }
    "ecl" -> fn(ecl) {
      case ecl {
        "amb" | "blu" | "brn" | "gry" | "grn" | "hzl" | "oth" -> True
        _ -> False
      }
    }
    "pid" -> fn(pid) {
      let Ok(id_regex) = regex.from_string("^(\\d){9}$")
      regex.check(with: id_regex, content: pid)
    }
    _ -> fn(_) { True }
  }
}

pub fn validate_fields(passport: Map(String, String)) -> Bool {
  required_fields
  |> list.all(fn(field) {
    let validator = get_field_validation(field)

    passport
    |> map.get(field)
    |> result.map(validator)
    |> result.unwrap(False)
  })
}

pub fn part_one() -> Int {
  read_passports()
  |> list.filter(validate_passport)
  |> list.length
}

pub fn part_two() -> Int {
  read_passports()
  |> list.filter(validate_fields)
  |> list.length
}

pub fn solve() {
  let one = part_one()
  let two = part_two()

  io.println(string.concat(["Part one: ", int.to_string(one)]))
  io.println(string.concat(["Part two: ", int.to_string(two)]))
}
