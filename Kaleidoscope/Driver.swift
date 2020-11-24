//
//  Driver.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 19/11/2020.
//

//import LLVM

//func runloop() {
////	LLVMLinkInMCJIT()
////	LLVMInitializeNativeTarget()
////	LLVMInitializeNativeAsmPrinter()
//
//  getNextToken()
////	runloop:
//    while true {
//    switch getCurrentToken() {
//    case .Def:
//      handleDefinition()
//    case .Extern:
//      handleExtern()
//    case .Character(.Semicolon):
//      getNextToken()
//    case .EOF:
//			break
//    case _:
//			handleTopLevelExpression()
//    }
//  }
//}
//
////private func dump(_ value: LLVMValueRef) {
////  LLVMDumpValue(value)
////}
//
//private func dump(dumpable: CustomStringConvertible) {
//	print(dumpable.description)
//}
//
//func handleDefinition() {
//  do {
//    let function = try parseFunctionDefinition()
////		let codegen = try function.codegen(currentCodeGenContext)
////		dump(codegen)
////    dump(function)
//		dump(dumpable: function)
//  } catch ParserError.Error(let error) {
//    print("parser error: \(error)")
//  } catch {
//    print("something went wrong!")
//  }
//}
//
//func handleExtern() {
//  do {
//    let externPrototype = try parseExternFunction()
//		dump(dumpable: externPrototype)
////		let codegen = try externPrototype.codegen(currentCodeGenContext)
////		dump(codegen)
////		print(codegen.debugDescription)
//  } catch ParserError.Error(let error) {
//    print("parser error: \(error)")
//  } catch {
//    print("something went wrong!")
//  }
//}
//
//func handleTopLevelExpression() {
//  do {
//    let topLevel = try parseTopLevelExpression()
////		let code = try topLevel.codegen(currentCodeGenContext)
////		let result = runFunction(code, module: currentCodeGenContext.module)
////		print("\(result)")
//    dump(dumpable: topLevel)
//  } catch ParserError.Error(let error) {
//    print("parser error: \(error)")
//  } catch {
//    print("something went wrong!")
//  }
//}
