//
//  Parser.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 18/11/2020.
//

import Foundation

// MARK: - ParserError

enum ParserError: Error {
  case Error(Token)
}

// MARK: - Parser

final class Parser {

  // MARK: Lifecycle

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  // MARK: Internal

  let tokens: [Token]
  var index = 0

  var currentToken: Token? {
    index < tokens.count ? tokens[index] : nil
  }

  func parseAST() throws -> AST {
    let ast = AST()
    print("current tok \(String(describing: currentToken))")
    while let tok = currentToken {
      switch tok {
      case .extern:
        ast.addExtern(try parseExtern())
      case .def:
        ast.addDefinition(try parseDefinition())
      default:
        let expr = try parseExpr()
        try consume(.semicolon)
        ast.addExpression(expr)
      }
    }
    return ast
  }

  // MARK: Private

  private func consumeToken() {
    index += 1
  }

  private func consume(_ token: Token) throws {
    guard let tok = currentToken else {
      throw ParserError.Error(token)
    }
    guard token == tok else {
      // token: (, tok: m
      fatalError("Error: token:\(token) tok:\(tok)")
    }
    consumeToken()
  }

  private func parseExpr() throws -> Expr {
    guard let token = currentToken else {
      fatalError("Unexpected EOF")
    }
    var expr: Expr
    switch token {
    /// ( <Expr> )
    case .leftParen:
      consumeToken()
      expr = try parseExpr()
      try consume(.rightParen)
    case let .number(value):
      consumeToken()
      expr = .number(value)
    case let .identifier(value):
      consumeToken()
      let params = try parseCommaSeparated(parseExpr)
      expr = .call(value, params)
    /// if <expr> then <expr> else <expr>
    case .if:
      consumeToken()
      let condition = try parseExpr()
      try consume(.then)
      let thenValue = try parseExpr()
      try consume(.else)
      let elseValue = try parseExpr()
      expr = .ifthenelse(condition, thenValue, elseValue)
    default:
      throw ParserError.Error(token)
    }

    if case let .operator(binaryOp)? = currentToken {
      consumeToken()
      let rhs = try parseExpr()
      expr = .binary(expr, binaryOp, rhs)
    }

    return expr
  }

  private func parseCommaSeparated<T>(_ parseFunction: () throws -> T) throws -> [T] {
    try consume(.leftParen)
    var values = [T]()
    while let token = currentToken, token != .rightParen {
      let value = try parseFunction()
      if case .comma? = currentToken {
        try consume(.comma)
      }
      values.append(value)
    }
    try consume(.rightParen)
    return values
  }

  private func parseDefinition() throws -> Definition {
    try consume(.def)
    let prototype = try parsePrototype()
    let expr = try parseExpr()
    let definition = Definition(prototype: prototype, expr: expr)
    try consume(.semicolon)
    return definition
  }

  private func parseIdentifier() throws -> String {
    guard let token = currentToken else {
      fatalError("unexpected token")
    }
    guard case let .identifier(name) = token else {
      throw ParserError.Error(token)
    }
    consumeToken()
    return name
  }

  private func parsePrototype() throws -> Prototype {
    let name = try parseIdentifier()
    let params = try parseCommaSeparated(parseIdentifier)
    return Prototype(name: name, params: params)
  }

  private func parseExtern() throws -> Prototype {
    try consume(.extern)
    let proto = try parsePrototype()
    try consume(.semicolon)
    return proto
  }

}
