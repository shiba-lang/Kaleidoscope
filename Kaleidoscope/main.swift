//
//  main.swift
//  Kaleidoscope
//
//  Created by Khoa Le on 24/11/2020.
//

import Foundation
import LLVM

// MARK: - String + Error

extension String: Error {}

typealias KSMainFunction = @convention(c) () -> Void

do {
  guard CommandLine.arguments.count > 1 else {
    throw "usage: kaleidoscope <file>"
  }

  let path = URL(fileURLWithPath: CommandLine.arguments[1])
  print(path)
  let input = try String(contentsOf: path, encoding: .utf8)
  let toks = Lexer(input: input).lex()
  let ast = try Parser(tokens: toks).parseAST()
  let codegen = CodeGen(ast: ast)
  try codegen.emit()
  try codegen.module.verify()
  let ksPath = path.deletingPathExtension().appendingPathExtension("ks")
  if FileManager.default.fileExists(atPath: ksPath.path) {
    try FileManager.default.removeItem(at: ksPath)
  }
  FileManager.default.createFile(atPath: ksPath.path, contents: nil)
  try codegen.module.print(to: ksPath.path)
  print("Successfully wrote LLVM IR to \(ksPath.lastPathComponent)")


  let objPath = path.deletingPathExtension().appendingPathExtension("o")
  if FileManager.default.fileExists(atPath: objPath.path) {
    try FileManager.default.removeItem(at: objPath)
  }

  let targetMachine = try TargetMachine()
  try targetMachine.emitToFile(
    module: codegen.module,
    type: .object,
    path: objPath.path
  )
  print("Successfully wrote binary object file to \(objPath.lastPathComponent)")

} catch {
  print("error: \(error)")
  exit(-1)
}
