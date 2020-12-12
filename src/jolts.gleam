import gleam/int
import gleam/io
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map
import gleam/result
import gleam/set
import gleam/string
import util.{last, read_file, sum}

pub fn get_test_joltages() -> List(Int) {
  "16
10
15
5
1
11
7
19
6
12
4"
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter_map(int.parse)
  |> list.sort(by: int.compare)
}

pub fn get_joltages() -> List(Int) {
  "./data/day10.txt"
  |> read_file
  |> list.map(string.trim)
  |> list.filter_map(int.parse)
  |> list.sort(by: int.compare)
}

pub fn find_differences(joltages: List(Int), selected: List(Int)) -> List(Int) {
  case joltages {
    [curr, next, ..rest] ->
      case next - curr {
        n if n <= 3 -> find_differences([next, ..rest], [curr, ..selected])
        _ -> find_differences([curr, ..rest], selected)
      }
    [last] -> [last, ..selected]
  }
}

pub fn get_selected_joltages(joltages: List(Int)) -> List(Int) {
  let device_joltage =
    joltages
    |> last
    |> result.map(fn(j) { j + 3 })
    |> result.unwrap(-1)

  joltages
  |> list.append([device_joltage])
  |> find_differences([0])
  |> list.reverse
}

pub fn part_one() -> Int {
  get_joltages()
  |> get_selected_joltages
  |> list.fold(
    [[]],
    fn(next, acc) {
      case acc {
        [[], ..rest] -> [[next], ..rest]
        [[existing], ..rest] -> [[next, existing], ..rest]
        [[left, right], ..rest] -> [[next, left], [left, right], ..rest]
      }
    },
  )
  |> list.fold(
    map.new(),
    fn(pair, counts) {
      let [left, right] = pair
      let difference = left - right
      map.update(
        counts,
        difference,
        fn(res) {
          res
          |> result.map(fn(j) { j + 1 })
          |> result.unwrap(1)
        },
      )
    },
  )
  |> io.debug
  |> map.to_list
  |> list.fold(
    1,
    fn(p, product) {
      let tuple(diff, count) = p
      case diff {
        1 | 3 -> product * count
        _ -> product
      }
    },
  )
}

// I based this on some existing solutions
pub fn part_two() -> Int {
  let joltages = get_joltages()

  let adapter_counts =
    joltages
    |> list.fold(
      map.from_list([tuple(0, 1)]),
      fn(joltage, sums) {
        [joltage - 1, joltage - 2, joltage - 3]
        |> list.map(fn(prev) {
          sums
          |> map.get(prev)
          |> result.unwrap(0)
        })
        |> sum
        |> fn(count) {
          map.update(
            sums,
            joltage,
            fn(curr) {
              curr
              |> result.map(fn(n) { n + count })
              |> result.unwrap(count)
            },
          )
        }
      },
    )

  joltages
  |> last
  |> result.unwrap(0)
  |> map.get(adapter_counts, _)
  |> result.unwrap(-1)
}
