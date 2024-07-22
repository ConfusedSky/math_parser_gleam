import argv
import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/string

// TODO: Add much better error types rather than having all errors be Nil

pub type Token {
  Number(Float)
  Plus
  Minus
  Multiply
  Divide
  Power
  LParen
  RParen
}

fn token_precedence(token: Token) -> Int {
  case token {
    Plus -> 1
    Minus -> 1
    Multiply -> 2
    Divide -> 2
    Power -> 3
    _ -> 0
  }
}

pub fn token_to_string(token: Token, round: Bool) -> String {
  case token {
    Number(n) ->
      case round {
        True -> n |> float.round |> int.to_string
        False -> n |> float.to_string
      }
    Plus -> "+"
    Minus -> "-"
    Multiply -> "*"
    Divide -> "/"
    Power -> "^"
    LParen -> "("
    RParen -> ")"
  }
}

fn is_numeric(c: String) -> Bool {
  case c {
    "0" -> True
    "1" -> True
    "2" -> True
    "3" -> True
    "4" -> True
    "5" -> True
    "6" -> True
    "7" -> True
    "8" -> True
    "9" -> True
    "." -> True
    _ -> False
  }
}

pub fn tokenize(input: String) -> List(Token) {
  let parse_number = fn(chunk) {
    let number = chunk |> string.join("")
    let number = {
      case string.contains(number, ".") {
        True -> number
        False -> number <> ".0"
      }
    }

    let assert Ok(number) = number |> float.parse
    Number(number)
  }

  input
  |> string.to_graphemes
  |> list.index_map(fn(c, i) { #(i, c) })
  |> iterator.from_list
  |> iterator.chunk(fn(tuple) {
    let #(i, c) = tuple

    // Group numberic values and make sure anything else is separated
    case is_numeric(c) {
      True -> -1
      False -> i
    }
  })
  |> iterator.filter(fn(chunk) {
    case chunk {
      [#(_, " ")] -> False
      [#(_, "\t")] -> False
      [#(_, "\n")] -> False
      _ -> True
    }
  })
  |> iterator.map(fn(chunk) {
    let chunk = chunk |> list.map(fn(t) { t.1 })

    case chunk {
      ["+"] -> Plus
      ["-"] -> Minus
      ["*"] -> Multiply
      ["/"] -> Divide
      ["^"] -> Power
      ["("] -> LParen
      [")"] -> RParen
      _ -> parse_number(chunk)
    }
  })
  |> iterator.to_list
}

type ToRpnState {
  ToRpnState(stack: List(Token), output: List(Token), paren_count: Int)
}

pub fn to_rpn(tokens: List(Token)) -> Result(List(Token), Nil) {
  let state = ToRpnState([], [], 0)
  let state =
    list.try_fold(tokens, state, fn(state, token) {
      case token, state {
        Number(_), _ -> Ok(ToRpnState(..state, output: [token, ..state.output]))

        LParen, _ ->
          Ok(
            ToRpnState(
              ..state,
              stack: [token, ..state.stack],
              paren_count: state.paren_count + 1,
            ),
          )

        RParen, ToRpnState(paren_count: 0, ..) -> Error(Nil)

        RParen, ToRpnState(paren_count: paren_count, ..) if paren_count > 0 -> {
          let #(additional_output, rest) =
            list.split_while(state.stack, fn(t) { t != LParen })
          // Pop the LParen
          let assert [_, ..rest] = rest

          Ok(ToRpnState(
            stack: rest,
            output: list.concat([additional_output, state.output]),
            paren_count: paren_count - 1,
          ))
        }

        // Down here it must by definition be an operator becuase it's not a number
        _, ToRpnState(stack: [], ..) -> Ok(ToRpnState(..state, stack: [token]))

        _, _ -> {
          let #(additional_output, rest) =
            list.split_while(state.stack, fn(t) {
              token_precedence(t) >= token_precedence(token)
            })
          Ok(
            ToRpnState(
              ..state,
              stack: [token, ..rest],
              output: list.concat([additional_output, state.output]),
            ),
          )
        }
      }
    })

  use state <- result.try(state)
  let state = case state.paren_count != 0 {
    True -> Error(Nil)
    False -> Ok(state)
  }

  use state <- result.try(state)
  let output =
    state.stack |> list.reverse |> list.append(state.output) |> list.reverse

  Ok(output)
}

pub fn eval(input: String) -> Result(Float, Nil) {
  input
  |> tokenize
  |> to_rpn
  |> result.try(fn(tokens) {
    list.try_fold(tokens, [], fn(stack, token) {
      case token, stack {
        Number(n), stack -> Ok([n, ..stack])

        Plus, [a, b, ..rest] -> Ok([a +. b, ..rest])

        Minus, [a, b, ..rest] -> Ok([b -. a, ..rest])

        Multiply, [a, b, ..rest] -> Ok([a *. b, ..rest])

        Divide, [a, b, ..rest] -> {
          case a == 0.0 {
            True -> Error(Nil)
            False -> Ok([b /. a, ..rest])
          }
        }

        Power, [a, b, ..rest] -> {
          let result = float.power(b, a)
          case result {
            Ok(result) -> Ok([result, ..rest])
            Error(_) -> Error(Nil)
          }
        }

        _, _ -> Error(Nil)
      }
    })
  })
  |> result.try(fn(stack) {
    case stack {
      [result] -> Ok(result)
      _ -> Error(Nil)
    }
  })
}

pub fn to_string(tokens: List(Token), round: Bool) -> String {
  list.map(tokens, token_to_string(_, round)) |> string.join(" ")
}

pub fn main() {
  case argv.load().arguments {
    [] -> io.print("Usage: math_parser_gleam <expression>")
    args -> {
      let expression = args |> string.join(" ")
      case expression |> eval {
        Ok(result) -> io.println(result |> float.to_string)
        Error(_) -> io.println("Error")
      }
    }
  }
}
