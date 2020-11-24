//
//  AST.swift
//  Kaleidoscope
//
//  Created by Khoa Le on 24/11/2020.
//

import Foundation

// MARK: - Definition

struct Definition {
  let prototype: Prototype
  let expr: Expr
}

// MARK: - Prototype

struct Prototype {
  let name: String
  let params: [String]
}

// MARK: - AST

final class AST {
  var externs = [Prototype]()
  var definitions = [Definition]()
  var expressions = [Expr]()
  var prototypeDict = [String: Prototype]()

  func prototype(name: String) -> Prototype? {
    return prototypeDict[name]
  }

  func addExpression(_ expression: Expr) {
    expressions.append(expression)
  }

  func addExtern(_ prototype: Prototype) {
    externs.append(prototype)
    prototypeDict[prototype.name] = prototype
  }

  func addDefinition(_ definition: Definition) {
    definitions.append(definition)
    prototypeDict[definition.prototype.name] = definition.prototype
  }
}
