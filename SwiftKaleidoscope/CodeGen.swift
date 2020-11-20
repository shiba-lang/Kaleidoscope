//
//  CodeGen.swift
//  SwiftKaleidoscope
//
//  Created by Khoa Le on 19/11/2020.
//

import LLVM_C

private let module = LLVMModuleCreateWithName("Kaleidoscope")
private let builder = LLVMCreateBuilder()
private let passManager = passManagerForModule(module!)

private func passManagerForModule(_ module: LLVMModuleRef) -> LLVMPassManagerRef {
  let passManager = LLVMCreateFunctionPassManagerForModule(module)
  LLVMAddBasicAliasAnalysisPass(passManager)
  LLVMAddInstructionCombiningPass(passManager)
  LLVMAddReassociatePass(passManager)
  LLVMAddGVNPass(passManager)
  LLVMAddCFGSimplificationPass(passManager)

  LLVMInitializeFunctionPassManager(passManager)

  return passManager!
}
