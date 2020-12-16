import gleam/int
import gleam/io
import gleam/iterator.{Iterator, Next}
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/string
import util.{drop_last, last}

pub const puzzle_input = "1,0,16,5,17,4"

pub fn get_puzzle() -> List(Int) {
  puzzle_input
  |> string.split(",")
  |> list.filter_map(int.parse)
  |> list.reverse
}

pub fn find_last(spoken: List(Int), value: Int, distance: Int) -> Int {
  case spoken {
    [] -> 0
    // Turns are 1-indexed
    [n, ..] if n == value -> distance + 1
    [_, ..rest] -> find_last(rest, value, distance + 1)
  }
}

pub fn take_turn(spoken: List(Int)) -> List(Int) {
  assert [last_spoken, ..rest] = spoken
  let next_spoken = find_last(rest, last_spoken, 0)

  [next_spoken, last_spoken, ..rest]
}

pub fn generate(puzzle: List(Int)) -> Iterator(List(Int)) {
  iterator.unfold(
    from: puzzle,
    with: fn(next_puzzle) {
      Next(element: next_puzzle, accumulator: take_turn(next_puzzle))
    },
  )
}

pub fn get_nth(puzzle: List(Int), nth: Int) -> Int {
  puzzle
  |> generate
  |> iterator.take(nth)
  |> last
  |> result.map(list.head)
  |> result.flatten
  |> result.unwrap(-1)
}

pub fn part_one() -> Int {
  get_puzzle()
  |> get_nth(2015)
}

pub type Game {
  Game(last_spoken: Int, spoken_at: Map(Int, Int), turn: Int)
}

pub fn get_game(puzzle: List(Int)) -> Game {
  assert Ok(last_spoken) = last(puzzle)
  Game(
    last_spoken: last_spoken,
    spoken_at: puzzle
    |> drop_last(1)
    |> list.index_map(fn(i, n) { tuple(n, i + 1) })
    |> map.from_list,
    turn: list.length(puzzle),
  )
}

pub fn play_game(game: Game) -> Game {
  case map.get(game.spoken_at, game.last_spoken) {
    Ok(turn) ->
      Game(
        last_spoken: game.turn - turn,
        spoken_at: map.insert(game.spoken_at, game.last_spoken, game.turn),
        turn: game.turn + 1,
      )
    Error(Nil) ->
      Game(
        last_spoken: 0,
        spoken_at: map.insert(game.spoken_at, game.last_spoken, game.turn),
        turn: game.turn + 1,
      )
  }
}

pub fn get_game_turn(game: Game, turn: Int) -> Result(Game, Nil) {
  game
  |> iterator.unfold(with: fn(game) {
    Next(element: game, accumulator: play_game(game))
  })
  |> iterator.find(fn(g: Game) { g.turn == turn })
}

pub fn part_one_new() -> Int {
  get_puzzle()
  |> list.reverse
  |> get_game
  |> get_game_turn(2020)
  |> result.map(fn(g: Game) { g.last_spoken })
  |> result.unwrap(-1)
}

pub fn part_two() -> Int {
  get_puzzle()
  |> list.reverse
  |> get_game
  |> get_game_turn(30_000_000)
  |> result.map(fn(g: Game) { g.last_spoken })
  |> result.unwrap(-1)
}

pub fn test_input() -> Int {
  [1, 2, 3]
  |> get_game
  |> get_game_turn(2020)
  |> result.map(fn(g: Game) { g.last_spoken })
  |> result.unwrap(-1)
}

pub fn test_input_pt2() -> Int {
  [1, 3, 2]
  |> get_game
  |> get_game_turn(30_000_000)
  |> result.map(fn(g: Game) { g.last_spoken })
  |> result.unwrap(-1)
}
