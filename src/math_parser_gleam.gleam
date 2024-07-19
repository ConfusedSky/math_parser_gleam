import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/string

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

pub fn to_rpn(tokens: List(Token)) -> List(Token) {
  io.debug("to_rpn " <> tokens |> to_string(False))
  let state = ToRpnState([], [], 0)
  let state =
    list.fold(tokens, state, fn(state, token) {
      io.debug(#(token |> token_to_string(False), state))
      case token, state.stack {
        Number(_), _ -> ToRpnState(..state, output: [token, ..state.output])
        // Down here it must by definition be an operator becuase it's not a number
        _, [] -> ToRpnState(..state, stack: [token, ..state.stack])
        _, _ -> {
          let #(additional_output, rest) =
            list.split_while(state.stack, fn(t) {
              token_precedence(t) >= token_precedence(token)
            })
          ToRpnState(
            ..state,
            stack: [token, ..rest],
            output: list.concat([additional_output, state.output]),
          )
        }
      }
    })
  let output =
    state.stack |> list.reverse |> list.append(state.output) |> list.reverse
  io.debug("=====")

  output
}

pub fn to_string(tokens: List(Token), round: Bool) -> String {
  list.map(tokens, token_to_string(_, round)) |> string.join(" ")
}

pub fn main() {
  io.println("Hello from math_parser_gleam!")
}
