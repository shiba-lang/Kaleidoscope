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

private let _identifierPredicate: LexerPredicate = {
  $0 != .EOF && isAlphaNumericCharacter($0)
}

private let _numberPredicate: LexerPredicate = {
  $0 != .EOF && isDigitCharacter($0)
}

private let _commentPredicate: LexerPredicate = {
  $0 != .EOF && $0 != .LineFeed && $0 != .CarriageReturn
}

private var _currentCharacter = ASCIICharacter.Space

private func _consumeUntil(_ predicate: LexerPredicate) -> String {
  var string = ""
  while predicate(_currentCharacter) {
    string += String(
      UnicodeScalar(UInt32(_currentCharacter.rawValue))!
    )
  }
  return string
}

func nextToken() -> Token {
  while isSpaceCharacter(_currentCharacter) {
    _currentCharacter = getASCIICharacter()
  }

  /// Attempt to create Identifier Token
  ///
  /// [A-Za-z][A-Za-z0-9]*
  if isDigitCharacter(_currentCharacter) {
    let integerPart = _consumeUntil(_numberPredicate)
    var decimalPoint = ""
    if _currentCharacter == .FullStop {
      decimalPoint = "."
      _currentCharacter = getASCIICharacter() // remove '.'
    }
    let fractionPart = _consumeUntil(_numberPredicate)
    let numberString = integerPart + decimalPoint + fractionPart
    if let number = Double(numberString) {
      return .Number(number)
    } else {
      print("Lex error: cant parse number '\(numberString)'")
    }
  }

  /// Consuming comments
  if _currentCharacter == .NumberSign {
    let comment = _consumeUntil(_commentPredicate)
    return .Comment(comment)
  }

  /// End of stream
  if _currentCharacter == .EOF {
    return .EOF
  }

  let character = _currentCharacter
  _currentCharacter = getASCIICharacter()
  return .Character(character)
}
