import gleeunit
import gleeunit/should

import math_parser_gleam

pub fn main() {
  gleeunit.main()
}

pub fn tokenize_test() {
  let tokenize = math_parser_gleam.tokenize

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Plus,
      math_parser_gleam.Number(2.0),
    ],
    tokenize("1+2"),
  )

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Multiply,
      math_parser_gleam.Number(2.0),
    ],
    tokenize("1*2"),
  )

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Minus,
      math_parser_gleam.Number(2.0),
    ],
    tokenize("1-2"),
  )

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Divide,
      math_parser_gleam.Number(2.0),
    ],
    tokenize("1/2"),
  )

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Multiply,
      math_parser_gleam.Number(2.0),
      math_parser_gleam.Minus,
      math_parser_gleam.Number(3.0),
    ],
    tokenize("1 * 2 - 3"),
  )

  should.equal(
    [
      math_parser_gleam.Number(3.0),
      math_parser_gleam.Plus,
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Multiply,
      math_parser_gleam.Number(2.0),
    ],
    tokenize("3 + 1 * 2"),
  )

  should.equal(
    [
      math_parser_gleam.Number(1.0),
      math_parser_gleam.Multiply,
      math_parser_gleam.LParen,
      math_parser_gleam.Number(2.0),
      math_parser_gleam.Minus,
      math_parser_gleam.Number(3.0),
      math_parser_gleam.RParen,
    ],
    tokenize("1 * (2 - 3)"),
  )

  should.equal(
    [
      math_parser_gleam.Number(2.6),
      math_parser_gleam.Power,
      math_parser_gleam.Number(32.0),
    ],
    tokenize("2.6 ^ 32"),
  )
}

pub fn to_rpn_test() {
  let test_fn = fn(s) {
    math_parser_gleam.tokenize(s)
    |> math_parser_gleam.to_rpn
    |> math_parser_gleam.to_string(True)
  }

  should.equal("1 2 +", test_fn("1+2"))
  should.equal("1 2 *", test_fn("1*2"))
  should.equal("1 2 /", test_fn("1/2"))
  should.equal("1 2 -", test_fn("1-2"))

  should.equal("1 2 * 3 -", test_fn("1 * 2 - 3"))
  should.equal("3 1 2 * +", test_fn("3 + 1 * 2"))
  should.equal("1 2 3 - *", test_fn("1 * (2 - 3)"))

  should.equal("3 4 2 1 - * +", test_fn("3 + 4 * (2 - 1)"))

  should.equal("3 4 2 1 - 2 * * +", test_fn("3 + 4 * ((2 - 1) * 2)"))

  should.equal("3 4 2 * 1 5 - 2 3 ^ ^ / +", test_fn("3+4*2/(1-5)^2^3"))
}
