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
}

// MARK: - Expr

typealias Expr = CustomStringConvertible

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
    "("
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
    "if " + condition.description + "\n"
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
    "for " + variable + " = "
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

private var currentToken = Token.EOF

func getNextToken() {
  currentToken = getToken()
}

func getCurrentToken() -> Token {
  currentToken
}

private func isCurrentTokenCharacter(_ character: ASCIICharacter) -> Bool {
  switch currentToken {
  case let .Character(tokenCharacter):
    return tokenCharacter == character
  case _:
    return false
  }
}

/// Install standard binary operators.
/// 1 is lowest precedence.
let operatorPrecedence: [ASCIICharacter: Int] = [
  .LessThanSign: 10, // <
  .PlusSign: 20, // +
  .Minus: 20, // -
  .Asterisk: 40, // *
]

func currentTokenPrecedence() -> Int {
  switch currentToken {
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
  getNextToken()
  return NumberExpr(value: number)
}

/// BinaryExpr ::= ('+' PrimaryExpr) *
/// Use Operator-precedence parser algorithm.
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

    let binaryOperator = currentToken
    getNextToken()

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
  switch currentToken {
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
    getNextToken()
    throw ParserError.Error("Can't parse \(currentToken)")
  }
}

/// IdentifierExpr
/// ::= identifier
/// ::= identifier '(' Expression* ')'
func parseIdentifierExpr(_ identifier: String) throws -> Expr {
  getNextToken()

  if !isCurrentTokenCharacter(.ParenthesesOpened) {
    return VariableExpr(name: identifier)
  }

  getNextToken() // eat '('

  var arguments = [Expr]()
  if !isCurrentTokenCharacter(.ParenthesesClosed) {
    do {
      while true {
        let argument = try parseExpression()
        arguments.append(argument)

        if isCurrentTokenCharacter(.ParenthesesClosed) {
          break
        }

        if !isCurrentTokenCharacter(.Comma) {
          throw ParserError.Error("expected ',' or ')'")
        }

        getNextToken()
      }
    } catch ParserError.Error(let error) {
      throw ParserError.Error(error)
    } catch {
      throw ParserError.Error("Something went wrong!")
    }
  }
  getNextToken() // eat ')'
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
    getNextToken() // eat 'if'

    let condition = try parseExpression()

    guard case .Then = currentToken else {
      throw ParserError.Error("expected 'then'")
    }

    getNextToken() // eat 'then'

    let thenBranch = try parseExpression()

    guard case .Else = currentToken else {
      throw ParserError.Error("expected 'else'")
    }

    getNextToken() // eat 'else'

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
    getNextToken() // eat 'for'

    guard case let .Identifier(variableName) = currentToken else {
      throw ParserError.Error("expected Identifier after 'for'")
    }

    getNextToken() // eat identifier

    guard case .Character(.EqualsSign) = currentToken else {
      throw ParserError.Error("expected '=' aftier 'for'")
    }

    getNextToken() // eat '='

    let start = try parseExpression()

    guard case .Character(.Comma) = currentToken else {
      throw ParserError.Error("expected ',' after start expression")
    }

    getNextToken() // eat ','

    let end = try parseExpression()

    // step value is not optional in our implementation
    guard case .Character(.Comma) = currentToken else {
      throw ParserError.Error("expected ',' after end expression")
    }

    getNextToken() // eat ','

    let step = try parseExpression()

    guard case .In = currentToken else {
      throw ParserError.Error("expected 'in' after step expression")
    }

    getNextToken() // eat 'in'

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
  guard case let .Identifier(prototypeName) = currentToken else {
    throw ParserError.Error("expected prototype name")
  }

  getNextToken() // eat identifier

  if !isCurrentTokenCharacter(.ParenthesesOpened) {
    throw ParserError.Error("expected '(' in prototype")
  }

  getNextToken() // eat '('

  var argumentNames = [String]()

  while true {
    if case let .Identifier(identifier) = currentToken {
      argumentNames.append(identifier)
    } else {
      break
    }
    getNextToken()
  }

  if !isCurrentTokenCharacter(.ParenthesesClosed) {
    throw ParserError.Error("expected ')' in prototype")
  }

  getNextToken() // eat ')'

  return Prototype(name: prototypeName, arguments: argumentNames)
}

/// FunctionDefinition
/// ::= extern Prototype
func parseExternFunction() throws -> Prototype {
  getNextToken() // eat 'extern'
  return try parsePrototype()
}

/// FunctionDefinition
/// ::= def Prototype Expression
func parseFunctionDefinition() throws -> Function {
  do {
    getNextToken() // eat 'def'
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
