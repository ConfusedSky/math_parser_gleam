import gleam/float
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

fn tokenize_number(input: List(String), acc: List(String)) -> #(String, String) {
  case input {
    [] -> #(string.join(list.reverse(acc), ""), "")
    [c, ..rest] -> {
      case is_numeric(c) {
        True -> tokenize_number(rest, [c, ..acc])
        False -> #(
          string.join(list.reverse(acc), ""),
          string.join([c, ..rest], ""),
        )
      }
    }
  }
}

fn tokenize_helper(input: String, acc: List(Token)) -> List(Token) {
  case input {
    "" -> acc
    " " <> rest -> tokenize_helper(rest, acc)
    "+" <> rest -> tokenize_helper(rest, [Plus, ..acc])
    "-" <> rest -> tokenize_helper(rest, [Minus, ..acc])
    "*" <> rest -> tokenize_helper(rest, [Multiply, ..acc])
    "/" <> rest -> tokenize_helper(rest, [Divide, ..acc])
    "^" <> rest -> tokenize_helper(rest, [Power, ..acc])
    "(" <> rest -> tokenize_helper(rest, [LParen, ..acc])
    ")" <> rest -> tokenize_helper(rest, [RParen, ..acc])
    value -> {
      let #(number, rest) = tokenize_number(string.to_graphemes(value), [])
      case string.length(number) {
        0 -> panic as { "Invalid character: " <> value }
        _ -> Nil
      }

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
  tokenize_helper(input, []) |> list.reverse
}

pub fn to_rpn(tokens: List(Token)) -> List(Token) {
  todo
}

pub fn token_to_string(token: Token) -> String {
  case token {
    Number(n) -> float.to_string(n)
    Plus -> "+"
    Minus -> "-"
    Multiply -> "*"
    Divide -> "/"
    Power -> "^"
    LParen -> "("
    RParen -> ")"
  }
}

pub fn to_string(tokens: List(Token)) -> String {
  list.map(tokens, token_to_string) |> string.concat
}

pub fn main() {
  io.println("Hello from math_parser_gleam!")
}
