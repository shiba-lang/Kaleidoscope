//
//  CodeGen.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 19/11/2020.
//

import LLVM

// MARK: - CodeGenError

enum CodeGenError: Error {
  case Error(String)
}

// MARK: - CodeGen

final class CodeGen {

  // MARK: Lifecycle

  init(name: String = "main", ast: AST) {
    module = Module(name: name)
    builder = IRBuilder(module: module)
    self.ast = ast
  }

  // MARK: Internal

  let module: Module
  let builder: IRBuilder
  let ast: AST
  var namedValues = [String: IRValue]()

  func emit() throws {
    for extern in ast.externs {
      _ = emitPrototype(extern)
    }
    for definition in ast.definitions {
      _ = try emitDefinition(definition)
    }
    try emitMain()
  }

  @discardableResult
  func emitDefinition(_ definition: Definition) throws -> Function {
    let function = emitPrototype(definition.prototype)

    for (index, arg) in definition.prototype.params.enumerated() {
      let param = function.parameter(at: index)!
      namedValues[arg] = param
    }

    let entryBlock = function.appendBasicBlock(named: "entry")
    builder.positionAtEnd(of: entryBlock)

    let expr = try emitExpr(definition.expr)
    builder.buildRet(expr)

    namedValues.removeAll()

    return function
  }

  // MARK: Private

  private func emitMain() throws {
    let mainType = FunctionType([], VoidType())
    let function = builder.addFunction("main", type: mainType)
    let entry = function.appendBasicBlock(named: "entry")
    builder.positionAtEnd(of: entry)

    let printfFn = emitPrintf()
    let formatString = builder.buildGlobalStringPtr("%f\n")

    for expr in ast.expressions {
      let value = try emitExpr(expr)
      _ = builder.buildCall(printfFn, args: [formatString, value])
    }
    builder.buildRetVoid()
  }

  private func emitPrintf() -> Function {
    if let function = module.function(named: "printf") {
      return function
    }
    let printfType = FunctionType(
      [PointerType(pointee: IntType.int8)],
      IntType.int32,
      variadic: true
    )
    return builder.addFunction("printf", type: printfType)
  }

  private func emitExpr(_ expr: Expr) throws -> IRValue {
    switch expr {
    case let .variable(name):
      guard let param = namedValues[name] else {
        throw CodeGenError.Error("unknown \(name)")
      }
      return param
    case let .number(value):
      return FloatType.double.constant(value)
    case let .binary(lhs, op, rhs):
      let lhsVal = try emitExpr(lhs)
      let rhsVal = try emitExpr(rhs)
      switch op {
      case .plus:
        return builder.buildAdd(lhsVal, rhsVal)
      case .minus:
        return builder.buildSub(lhsVal, rhsVal)
      case .divide:
        return builder.buildDiv(lhsVal, rhsVal)
      case .times:
        return builder.buildMul(lhsVal, rhsVal)
      case .mod:
        return builder.buildRem(lhsVal, rhsVal)
      case .equals:
        let comparison = builder.buildFCmp(lhsVal, rhsVal, .orderedEqual)
        return builder.buildIntToFP(
          comparison,
          type: FloatType.double,
          signed: false
        )
      }
    case let .ifthenelse(condition, thenExpr, elseExpr):
      let ifCondition = builder.buildFCmp(
        try emitExpr(condition),
        FloatType.double.constant(0.0),
        .orderedNotEqual
      )
      let thenBasicBlock = builder.currentFunction!.appendBasicBlock(named: "then")
      let elseBasicBlock = builder.currentFunction!.appendBasicBlock(named: "then")
      let mergeBasicBlock = builder.currentFunction!.appendBasicBlock(named: "then")

      builder.buildCondBr(
        condition: ifCondition,
        then: thenBasicBlock,
        else: elseBasicBlock
      )
      builder.positionAtEnd(of: thenBasicBlock)

      let thenVal = try emitExpr(thenExpr)
      builder.buildBr(mergeBasicBlock)

      builder.positionAtEnd(of: elseBasicBlock)
      let elseVal = try emitExpr(elseExpr)
      builder.buildBr(mergeBasicBlock)

      builder.positionAtEnd(of: mergeBasicBlock)

      let phi = builder.buildPhi(FloatType.double)
      phi.addIncoming([
        (thenVal, thenBasicBlock),
        (elseVal, elseBasicBlock),
      ])
      return phi

    case let .call(name, args):
      guard let prototype = ast.prototype(name: name),
            prototype.params.count == args.count else
      {
        throw CodeGenError.Error("unknown function \(name)")
      }
      let args = try args.map(emitExpr)
      let function = emitPrototype(prototype)
      return builder.buildCall(function, args: args)
    }
  }

  @discardableResult
  private func emitPrototype(_ prototype: Prototype) -> Function {
    if let function = module.function(named: prototype.name) {
      return function
    }
    let argTypes = [IRType](
      repeating: FloatType.double,
      count: prototype.params.count
    )
    let functionType = FunctionType(argTypes, FloatType.double)
    let function = builder.addFunction(prototype.name, type: functionType)
    for (var param, name) in zip(function.parameters, prototype.params) {
      param.name = name
    }
    return function
  }

}
