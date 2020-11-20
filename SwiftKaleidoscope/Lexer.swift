//
//  Lexer.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 18/11/2020.
//

import Darwin

private typealias LexerPredicate = ((ASCIICharacter) -> Bool)

// MARK: - Token

enum Token {
  case EOF
  case Def
  case Extern
  case Identifier(String)
  case Comment(String)
  case Number(Double)
  case Character(ASCIICharacter)

  case If
  case Then
  case Else

  case For
  case In
}

private let identifierPredicate: LexerPredicate = {
  $0 != .EOF && isAlphaNumericCharacter($0)
}

private let numberPredicate: LexerPredicate = {
  $0 != .EOF && isDigitCharacter($0)
}

private let commentPredicate: LexerPredicate = {
  $0 != .EOF && $0 != .LineFeed && $0 != .CarriageReturn
}

private var currentCharacter: ASCIICharacter = .Space

private func consumeUntil(_ predicate: LexerPredicate) -> String {
  var string = ""
  while predicate(currentCharacter) {
    string += String(
      UnicodeScalar(UInt32(currentCharacter.rawValue))!
    )
  }
  return string
}

func getToken() -> Token {
  while isSpaceCharacter(currentCharacter) {
    currentCharacter = getASCIICharacter()
  }

  /// Attempt to create Identifier Token
  ///
  /// [A-Za-z][A-Za-z0-9]*
  if isDigitCharacter(currentCharacter) {
    let integerPart = consumeUntil(numberPredicate)
    var decimalPoint = ""
    if currentCharacter == .FullStop {
      decimalPoint = "."
      currentCharacter = getASCIICharacter() // eat '.'
    }
    let fractionPart = consumeUntil(numberPredicate)
    let numberString = integerPart + decimalPoint + fractionPart
    if let number = Double(numberString) {
      return .Number(number)
    } else {
      print("Lex error: cant parse number '\(numberString)'")
    }
  }

  /// Consuming comments
  if currentCharacter == .NumberSign {
    let comment = consumeUntil(commentPredicate)
    return .Comment(comment)
  }

  /// End of stream
  if currentCharacter == .EOF {
    return .EOF
  }

  let character = currentCharacter
  currentCharacter = getASCIICharacter()
  return .Character(character)
}
