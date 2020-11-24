//
//  Lexer.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 18/11/2020.
//

import Darwin

// MARK: - BinaryOperator

enum BinaryOperator: UnicodeScalar {
  case plus = "+"
  case minus = "-"
  case times = "*"
  case divide = "/"
  case mod = "%"
  case equals = "="
}

// MARK: - Token

enum Token: Equatable {
  case leftParen
  case rightParen
  case def
  case extern
  case comma
  case semicolon

  case EOF

  case identifier(String)
  case number(Double)
  case `operator`(BinaryOperator)

  case `if`
  case then
  case `else`

  case `for`
  case `in`
}

// MARK: - Lexer

final class Lexer {

  // MARK: Lifecycle

  init(input: String) {
    self.input = input
    index = input.startIndex
  }

  // MARK: Internal

  let input: String
  var index: String.Index

  func lex() -> [Token] {
    var toks = [Token]()
    while let tok = nextToken() {
      toks.append(tok)
    }
    return toks
  }

  // MARK: Private

  private var currentCharacter: Character? {
    index < input.endIndex ? input[index] : nil
  }

  private func readIdentifierOrNumber() -> String {
    var str = ""
    while let char = currentCharacter, char.isAlphanumeric || char == "." {
      str.append(char)
      nextIndex()
    }
    return str
  }

  private func nextToken() -> Token? {
    /// Skip all space untils non-space
    while let char = currentCharacter, char.isSpace {
      nextIndex()
    }

    guard let currentChar = currentCharacter else {
      return nil
    }

    /// Attempt to creat single scalar tokens
    let singleTokDict: [Character: Token] = [
      ",": .comma,
      "(": .leftParen,
      ")": .rightParen,
      ";": .semicolon,
      "+": .operator(.plus),
      "-": .operator(.minus),
      "*": .operator(.times),
      "/": .operator(.divide),
      "%": .operator(.mod),
      "=": .operator(.equals),
    ]
    if let tok = singleTokDict[currentChar] {
      nextIndex()
      return tok
    }

    /// Attempt to create Identifier Token
    ///
    /// [A-Za-z][A-Za-z0-9]*
    if currentChar.isAlphanumeric {
      let str = readIdentifierOrNumber()
      if let number = Double(str) {
        return .number(number)
      }

      switch str {
      case "def": return .def
      case "extern": return .extern
      case "if": return .if
      case "then": return .then
      case "else": return .else
      case "for": return .for
      case "in": return .in
      default:
        return .identifier(str)
      }
    }
    return nil
  }

  private func nextIndex() {
    input.formIndex(after: &index)
  }

}
