//
//  Utils.swift
//  Kaleidoscope
//
//  Created by Khoa Le on 24/11/2020.
//

import Foundation

extension Character {
  var value: Int32 {
    return Int32(String(self).unicodeScalars.first!.value)
  }
  var isSpace: Bool {
    return isspace(value) != 0
  }
  var isAlphanumeric: Bool {
    return isalnum(value) != 0 || self == "_"
  }
}
