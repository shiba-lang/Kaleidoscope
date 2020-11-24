//
//  Expr.swift
//  Kaleidoscope
//
//  Created by Khoa Le on 24/11/2020.
//

import Foundation

indirect enum Expr {
  case number(Double)
  case variable(String)
  case binary(Expr, BinaryOperator, Expr)
  case ifthenelse(Expr, Expr, Expr)
  case call(String, [Expr])
}
