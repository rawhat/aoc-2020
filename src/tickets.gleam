import gleam/int
import gleam/iterator
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/pair
import gleam/regex.{Match}
import gleam/result
import gleam/set.{Set}
import gleam/string
import util.{from, read_file, sum, take_while}

pub type Range {
  Range(from: Int, to: Int)
}

pub fn contains(range: Range, value: Int) {
  value >= range.from && value <= range.to
}

pub type Rule {
  Rule(field: String, ranges: List(Range))
}

pub const rule_string = "(.+): (\\d+)\-(\\d+) or (\\d+)\-(\\d+)"

pub fn get_range_value(digits: String) -> Int {
  digits
  |> int.parse
  |> result.unwrap(-1)
}

pub fn read_rules() -> List(Rule) {
  assert Ok(rule_regex) = regex.from_string(rule_string)

  "./data/day16-rules.txt"
  |> read_file
  |> list.map(string.trim)
  |> list.map(regex.scan(rule_regex, _))
  |> list.map(fn(m) {
    assert [
      Match(
        submatches: [
          Some(field),
          Some(first_from),
          Some(first_to),
          Some(second_from),
          Some(second_to),
        ],
        ..,
      ),
    ] = m

    Rule(
      field: field,
      ranges: [
        Range(from: get_range_value(first_from), to: get_range_value(first_to)),
        Range(
          from: get_range_value(second_from),
          to: get_range_value(second_to),
        ),
      ],
    )
  })
}

pub type Ticket {
  Ticket(values: List(Int))
}

pub fn read_other_tickets() -> List(Ticket) {
  "./data/day16-nearby.txt"
  |> read_file
  |> list.map(string.trim)
  |> list.map(string.split(_, ","))
  |> list.map(fn(values) {
    values
    |> list.map(get_range_value)
    |> Ticket
  })
}

pub fn read_my_ticket() -> Ticket {
  "./data/day16-ticket.txt"
  |> read_file
  |> list.head
  |> result.unwrap("")
  |> string.trim
  |> string.split(",")
  |> list.map(get_range_value)
  |> Ticket
}

pub fn get_valid_values(rules: List(Range), valid: Set(Int)) -> Set(Int) {
  case rules {
    [] -> valid
    [Range(from: from, to: to), ..rest] ->
      iterator.range(from: from, to: to)
      |> iterator.to_list
      |> set.from_list
      |> set.union(valid)
      |> get_valid_values(rest, _)
  }
}

pub fn part_one() -> Int {
  let valid_values =
    read_rules()
    |> list.map(fn(rule: Rule) { rule.ranges })
    |> list.flatten
    |> get_valid_values(set.new())

  read_other_tickets()
  |> list.map(fn(ticket: Ticket) {
    ticket.values
    |> list.filter(fn(value) { set.contains(valid_values, value) == False })
  })
  |> list.flatten
  |> sum
}

pub fn valid_tickets(tickets: List(Ticket)) -> List(Ticket) {
  let valid_values =
    read_rules()
    |> list.map(fn(rule: Rule) { rule.ranges })
    |> list.flatten
    |> get_valid_values(set.new())

  tickets
  |> list.filter(fn(ticket: Ticket) {
    ticket.values
    |> list.all(fn(value) { set.contains(valid_values, value) == True })
  })
}

pub fn rules_for_position(
  rules: Map(Int, List(Rule)),
  valid: Map(Int, Rule),
) -> Map(Int, Rule) {
  let is_empty =
    rules
    |> map.values
    |> list.all(fn(l) { list.length(l) == 0 })

  case is_empty {
    True -> valid
    False ->
      rules
      |> map.to_list
      |> list.find(fn(p) {
        assert tuple(_, rules) = p
        list.length(rules) == 1
      })
      |> result.map(fn(r) {
        assert tuple(position, [rule]) = r
        let new_rules =
          rules
          |> map.to_list
          |> list.map(fn(p) {
            assert tuple(position, rules_to_update) = p
            tuple(position, list.filter(rules_to_update, fn(r) { r != rule }))
          })
          |> map.from_list
        tuple(new_rules, map.insert(valid, position, rule))
      })
      |> result.unwrap(tuple(rules, valid))
      |> fn(p) {
        assert tuple(new_rules, new_valid) = p
        rules_for_position(new_rules, new_valid)
      }
  }
}

pub fn part_two() -> Int {
  let rules = read_rules()

  let my_ticket = read_my_ticket()

  let valid_tickets =
    read_other_tickets()
    |> valid_tickets
    |> list.append([my_ticket])

  let ordered_rule_sets: Map(Int, List(Int)) =
    valid_tickets
    |> list.fold(
      map.new(),
      fn(ticket: Ticket, m) {
        ticket.values
        |> list.index_map(fn(index, value) { tuple(index, value) })
        |> list.fold(
          m,
          fn(p, acc) {
            assert tuple(index, value) = p
            map.update(
              acc,
              index,
              fn(res) {
                case res {
                  Ok(rest) -> [value, ..rest]
                  _ -> [value]
                }
              },
            )
          },
        )
      },
    )

  let rule_to_position =
    from(0)
    |> iterator.map(map.get(ordered_rule_sets, _))
    |> take_while(result.is_ok)
    |> iterator.map(result.unwrap(_, []))
    |> iterator.map(fn(values) {
      rules
      |> list.filter(fn(rule: Rule) {
        values
        |> list.all(fn(value) {
          rule.ranges
          |> list.any(contains(_, value))
        })
      })
    })
    |> iterator.to_list
    |> list.index_map(fn(i, rules) { tuple(i, rules) })
    |> map.from_list
    |> rules_for_position(map.new())
    |> map.to_list
    |> list.map(pair.swap)
    |> map.from_list

  rules
  |> list.filter(fn(rule: Rule) { string.contains(rule.field, "departure") })
  |> list.filter_map(map.get(rule_to_position, _))
  |> list.filter_map(list.at(my_ticket.values, _))
  |> list.fold(1, fn(m, n) { m * n })
}
