import gleam/float
import gleam/int
import gleam/io
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

fn tokenize_helper(input: List(String), acc: List(Token)) -> List(Token) {
  case input {
    [] -> acc
    [" ", ..rest] -> tokenize_helper(rest, acc)
    ["+", ..rest] -> tokenize_helper(rest, [Plus, ..acc])
    ["-", ..rest] -> tokenize_helper(rest, [Minus, ..acc])
    ["*", ..rest] -> tokenize_helper(rest, [Multiply, ..acc])
    ["/", ..rest] -> tokenize_helper(rest, [Divide, ..acc])
    ["^", ..rest] -> tokenize_helper(rest, [Power, ..acc])
    ["(", ..rest] -> tokenize_helper(rest, [LParen, ..acc])
    [")", ..rest] -> tokenize_helper(rest, [RParen, ..acc])
    value -> {
      let #(number, rest) = value |> list.split_while(is_numeric)
      case list.length(number) {
        0 -> panic as { "Invalid character: " <> value |> string.join("") }
        _ -> Nil
      }

      let number = number |> string.join("")
      let number = {
        case string.contains(number, ".") {
          True -> number
          False -> number <> ".0"
        }
      }

      let assert Ok(number) = number |> float.parse
      tokenize_helper(rest, [Number(number), ..acc])
    }
  }
}

pub fn tokenize(input: String) -> List(Token) {
  tokenize_helper(input |> string.to_graphemes, []) |> list.reverse
}

fn to_rpn_helper_token(
  token: Token,
  tokens: List(Token),
  stack: List(Token),
  output: List(Token),
) {
  case token, stack {
    Number(_), _ -> to_rpn_helper(tokens, stack, [token, ..output])
    // Down here it must by definition be an operator becuase it's not a number
    _, [] -> to_rpn_helper(tokens, [token, ..stack], output)
    _, [top, ..rest] -> {
      let precedence = token_precedence(token)
      let top_precedence = token_precedence(top)
      case precedence > top_precedence {
        True -> to_rpn_helper(tokens, [token, ..stack], output)
        False -> to_rpn_helper_token(token, tokens, rest, [top, ..output])
      }
    }
  }
}

fn to_rpn_helper(tokens: List(Token), stack: List(Token), output: List(Token)) {
  io.println(
    "to_rpn_helper "
    <> tokens |> to_string(False)
    <> ", "
    <> stack |> to_string(False)
    <> ", "
    <> output |> to_string(False),
  )

  case tokens {
    [] -> stack |> list.reverse |> list.append(output)
    [token, ..rest] -> to_rpn_helper_token(token, rest, stack, output)
  }
}

pub fn to_rpn(tokens: List(Token)) -> List(Token) {
  io.println("to_rpn " <> tokens |> to_string(False))
  let result = to_rpn_helper(tokens, [], []) |> list.reverse
  io.println("=====")

  result
}

pub fn to_string(tokens: List(Token), round: Bool) -> String {
  list.map(tokens, token_to_string(_, round)) |> string.join(" ")
}

pub fn main() {
  io.println("Hello from math_parser_gleam!")
}
