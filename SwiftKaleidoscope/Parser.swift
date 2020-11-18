//
//  Parser.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 18/11/2020.
//

import Foundation

// MARK: - ParserError

enum ParserError: Error {
  case Error(String)
  case generalError
}

// MARK: - Expr

protocol Expr: CustomStringConvertible {}

// MARK: - NumberExpr

struct NumberExpr: Expr {
  let value: Double
  var description: String {
    String(value)
  }
}

// MARK: - VariableExpr

struct VariableExpr: Expr {
  let name: String
  var description: String {
    name
  }
}

// MARK: - BinaryExpr

struct BinaryExpr: Expr {
  let binaryOperator: ASCIICharacter
  let lhs: Expr
  let rhs: Expr

  var description: String {
    return "("
      + binaryOperator.description
      + lhs.description
      + " "
      + rhs.description
      + ")"
  }
}

// MARK: - CallExpr

struct CallExpr: Expr {
  let name: String
  let arguments: [Expr]
  var description: String {
    var argumentsDescription = [String]()
    arguments.forEach { argument in
      argumentsDescription.append(argument.description)
    }
    return name
      + "("
      + argumentsDescription.joined(separator: ", ")
      + ")"
  }
}

// MARK: - IfExpr

struct IfExpr: Expr {
  let condition: Expr
  let thenBranch: Expr
  let elseBranch: Expr

  var description: String {
    return "if " + condition.description + "\n"
      + "then " + thenBranch.description + "\n"
      + "else" + elseBranch.description
  }
}

// MARK: - ForExpr

struct ForExpr: Expr {
  let variable: String
  let start: Expr
  let end: Expr
  let step: Expr
  let body: Expr

  var description: String {
    return "for " + variable + " = "
      + start.description + ", "
      + end.description + " "
      + step.description
      + " in\n" + body.description
  }
}

// MARK: - Prototype

struct Prototype: Expr {
  let name: String
  let arguments: [String]

  var description: String {
    name + "(" + arguments.joined(separator: " ") + ")"
  }
}

// MARK: - Function

struct Function: Expr {
  let prototype: Prototype
  let body: Expr

  var description: String {
    return prototype.name == ""
      ? "__top_level_expression__\n" + body.description
      : "def " + prototype.description + "\n" + body.description
  }
}

private var _currentToken = Token.EOF

func consumeToken() {
  _currentToken = nextToken()
}

func getCurrentToken() -> Token {
  _currentToken
}

private func _isCurrentTokenCharacter(_ character: ASCIICharacter) -> Bool {
  switch _currentToken {
  case let .Character(tokenCharacter):
    return tokenCharacter == character
  case _:
    return false
  }
}

let operatorPrecedence = [
  ASCIICharacter.LessThanSign: 10,
  ASCIICharacter.PlusSign: 20,
  ASCIICharacter.Minus: 20,
  ASCIICharacter.Asterisk: 40,
]

func currentTokenPrecedence() -> Int {
  switch _currentToken {
  case let .Character(character):
    let precedence = operatorPrecedence[character]
    switch precedence {
    case let .some(precedence):
      return precedence
    case _: break
    }
  case _:
    break
  }
  return -1
}

/// NumberExpr ::= number
func parseNumberExpression(_ number: Double) -> Expr {
  consumeToken()
  return NumberExpr(value: number)
}

/// BinaryExpr ::= ('+' PrimaryExpr) *
/// It use Operator-precedence parser.
/// More info:
/// https://en.wikipedia.org/wiki/Operator-precedence_parser
func parseBinaryExpression(
  _ expressionPrecedence: Int,
  lhs: Expr
) throws -> Expr {
  var lhs = lhs
  while true {
    let currentPrecedence = currentTokenPrecedence()
    if currentPrecedence < expressionPrecedence {
      return lhs
    }

    let binaryOperator = _currentToken
    consumeToken()

    do {
      var rhs = try parsePrimaryExpression()
      let nextPrecedence = currentTokenPrecedence()

      if currentPrecedence < nextPrecedence {
        rhs = try parseBinaryExpression(currentPrecedence + 1, lhs: rhs)
      }

      if case let .Character(character) = binaryOperator {
        lhs = BinaryExpr(binaryOperator: character, lhs: lhs, rhs: rhs)
      }
    } catch ParserError.Error(let error) {
      throw ParserError.Error(error)
    } catch {
      throw ParserError.Error("Something went wrong!")
    }
  }
}


/// PrimaryExpr
/// ::= IdentifierExpr
/// ::= NumberExpr
/// ::= ParenExpr
/// ::= IfExpr
/// ::= ForExpr

func parsePrimaryExpression() throws -> Expr {
  switch _currentToken {
  case let .Number(number):
    return parseNumberExpression(number)
  case let .Identifier(identifier):
    return try parseIdentifierExpr(identifier)
  case .Character(ASCIICharacter.ParenthesesOpened):
    return try parseParenExpression()
  case .If:
    return try parseIfExpression()
  case .For:
    return try parseForExpression()
  case _:
    consumeToken()
    throw ParserError.Error("Can't parse \(_currentToken)")
  }
}

/// IdentifierExpr
/// ::= identifier
/// ::= identifier '(' Expression* ')'
func parseIdentifierExpr(_ identifier: String) throws -> Expr {
  consumeToken()

  if !_isCurrentTokenCharacter(.ParenthesesOpened) {
    return VariableExpr(name: identifier)
  }

  consumeToken() // eat '('

  var arguments = [Expr]()
  if !_isCurrentTokenCharacter(.ParenthesesClosed) {
    do {
      while true {
        let argument = try parseExpression()
        arguments.append(argument)

        if _isCurrentTokenCharacter(.ParenthesesClosed) {
          break
        }

        if !_isCurrentTokenCharacter(.Comma) {
          throw ParserError.Error("expected ',' or ')'")
        }

        consumeToken()
      }
    } catch ParserError.Error(let error) {
      throw ParserError.Error(error)
    } catch {
      throw ParserError.Error("Something went wrong!")
    }
  }
  consumeToken() // eat ')'
  return CallExpr(name: identifier, arguments: arguments)
}

/// Expression
/// ::= PrimaryExpression BinaryExpression
func parseExpression() throws -> Expr {
  do {
    let lhs = try parsePrimaryExpression()
    return try parseBinaryExpression(0, lhs: lhs)
  } catch ParserError.Error(let error) {
    throw ParserError.Error(error)
  } catch {
    throw ParserError.Error("Something went wrong!")
  }
}

/// ParenExpr
/// ::= '(' + Expresion + ')'
func parseParenExpression() throws -> Expr {
  do {
    let lhs = try parsePrimaryExpression()
    return try parseBinaryExpression(0, lhs: lhs)
  } catch ParserError.Error(let error) {
    throw ParserError.Error(error)
  } catch {
    throw ParserError.Error("Something went wrong!")
  }
}

func parseIfExpression() throws -> Expr {
  do {
    consumeToken() // eat 'if'

    let condition = try parseExpression()

    guard case .Then = _currentToken else {
      throw ParserError.Error("expected 'then'")
    }

    consumeToken() // eat 'then'

    let thenBranch = try parseExpression()

    guard case .Else = _currentToken else {
      throw ParserError.Error("expected 'else'")
    }

    consumeToken() // eat 'else'

    let elseBranch = try parseExpression()
    return IfExpr(
      condition: condition,
      thenBranch: thenBranch,
      elseBranch: elseBranch
    )
  } catch ParserError.Error(let error) {
    throw ParserError.Error(error)
  } catch {
    throw ParserError.Error("Something went wrong!")
  }

}

/// ForExpr
/// ::= for Identifier = Expr, Expr, Expr in Expr
func parseForExpression() throws -> Expr {
  do {
    consumeToken() // eat 'for'

    guard case let .Identifier(variableName) = _currentToken else {
      throw ParserError.Error("expected Identifier after 'for'")
    }

    consumeToken() // eat identifier

    guard case .Character(.EqualsSign) = _currentToken else {
      throw ParserError.Error("expected '=' aftier 'for'")
    }

    consumeToken() // eat '='

    let start = try parseExpression()

    guard case .Character(.Comma) = _currentToken else {
      throw ParserError.Error("expected ',' after start expression")
    }

    consumeToken() // eat ','

    let end = try parseExpression()

    // step value is not optional in our implementation
    guard case .Character(.Comma) = _currentToken else {
      throw ParserError.Error("expected ',' after end expression")
    }

    consumeToken() // eat ','

    let step = try parseExpression()

    guard case .In = _currentToken else {
      throw ParserError.Error("expected 'in' after step expression")
    }

    consumeToken() // eat 'in'

    let body = try parseExpression()

    return ForExpr(
      variable: variableName,
      start: start,
      end: end,
      step: step,
      body: body
    )
  } catch {
    throw error
  }
}

/// Prototype
/// ::= IdentifierExpr '(' IdentifierExpr* ')'
func parsePrototype() throws -> Prototype {
  guard case let .Identifier(prototypeName) = _currentToken else {
    throw ParserError.Error("expected prototype name")
  }

  consumeToken() // eat identifier

  if !_isCurrentTokenCharacter(.ParenthesesOpened) {
    throw ParserError.Error("expected '(' in prototype")
  }

  consumeToken() // eat '('

  var argumentNames = [String]()

  while true {
    if case let .Identifier(identifier) = _currentToken {
      argumentNames.append(identifier)
    } else {
      break
    }
    consumeToken()
  }

  if !_isCurrentTokenCharacter(.ParenthesesClosed) {
    throw ParserError.Error("expected ')' in prototype")
  }

  consumeToken() // eat ')'

  return Prototype(name: prototypeName, arguments: argumentNames)
}

/// FunctionDefinition
/// ::= extern Prototype
func parseExternFunction() throws -> Prototype {
  consumeToken() // eat 'extern'
  return try parsePrototype()
}

/// FunctionDefinition
/// ::= def Prototype Expression
func parseFunctionDefinition() throws -> Function {
  do {
    consumeToken() // eat 'def'
    let prototype = try parsePrototype()
    let body = try parseExpression()
    return Function(prototype: prototype, body: body)
  } catch ParserError.Error(let error) {
    throw ParserError.Error(error)
  }
}

/// TopLevelExpression
/// ::= Expression
func parseTopLevelExpression() throws -> Function {
  do {
    let topLevelExpr = try parseExpression()
    let prototype = Prototype(name: "", arguments: [])
    return Function(prototype: prototype, body: topLevelExpr)
  } catch ParserError.Error(let error) {
    throw ParserError.Error(error)
  }
}
