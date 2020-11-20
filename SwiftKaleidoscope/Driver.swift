//
//  Driver.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 19/11/2020.
//

import LLVM_C

func runloop() {
  getNextToken()
  runloop:
    while true {
    switch getCurrentToken() {
    case .Def:
      handleDefinition()
    case .Extern:
      handleExtern()
    case .Character(.Semicolon):
      getNextToken()
    case .EOF:
			break runloop
    case _:
			handleTopLevelExpression()
    }
  }
}

private func dump(_ value: LLVMValueRef) {
  print(value)
  LLVMDumpValue(value)
}

func handleDefinition() {
  do {
    let function = try parseFunctionDefinition()
    dump(function)
  } catch ParserError.Error(let error) {
    print("parser error: \(error)")
  } catch {
    print("something went wrong!")
  }
}

func handleExtern() {
  do {
    let externPrototype = try parseExternFunction()
    print(externPrototype.description)
  } catch ParserError.Error(let error) {
    print("parser error: \(error)")
  } catch {
    print("something went wrong!")
  }
}

func handleTopLevelExpression() {
  do {
    let topLevel = try parseTopLevelExpression()
    print(topLevel.description)
  } catch ParserError.Error(let error) {
    print("parser error: \(error)")
  } catch {
    print("something went wrong!")
  }
}
